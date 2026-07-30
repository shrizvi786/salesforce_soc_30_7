trigger PayrollTrigger on Payroll__c (before update, after insert) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();

    // Preload Invoice Line Items grouped by Purchase Order
    Map<String, List<Invoice_Line_Item__c>> poToInvoiceLines = new Map<String, List<Invoice_Line_Item__c>>();

    for (Invoice_Line_Item__c ili : [
        SELECT Id, Purchase_Order__c, Service_Date__c,
               Invoice__r.Id,
               Invoice__r.Name,
               Invoice__r.Opportunity__r.Id,
               Invoice__r.Opportunity__r.Consultant_Daily_Rate__c
        FROM Invoice_Line_Item__c
        WHERE Purchase_Order__c != null
          AND Service_Date__c != null
          AND Invoice__r.Opportunity__r.Consultant_Daily_Rate__c != null
    ]) {
        if (!poToInvoiceLines.containsKey(ili.Purchase_Order__c)) {
            poToInvoiceLines.put(ili.Purchase_Order__c, new List<Invoice_Line_Item__c>());
        }
        poToInvoiceLines.get(ili.Purchase_Order__c).add(ili);
    }

    for (Payroll__c payroll : Trigger.new) {
        if (String.isBlank(payroll.Name)) continue;

        String[] parts = payroll.Name.split('-');
        if (parts.size() < 4) continue;

        String poRaw = parts[parts.size() - 1].trim();
        String yearStr = poRaw.contains('(') && poRaw.endsWith(')') ?
            poRaw.substring(poRaw.indexOf('(') + 1, poRaw.indexOf(')')) :
            String.valueOf(payroll.CreatedDate.year());
        String purchaseOrder = poRaw.contains('(') ? poRaw.substring(0, poRaw.indexOf('(')).trim() : poRaw;

        String datePart = parts[2].trim();
        List<String> rawDates = new List<String>();
        for (String d : datePart.split(',')) rawDates.add(d.trim());

        if (!poToInvoiceLines.containsKey(purchaseOrder)) continue;
        List<Invoice_Line_Item__c> invoiceLines = poToInvoiceLines.get(purchaseOrder);

        // Normalize target dates from payroll name
        Map<Date, Boolean> dateHalfDayMap = new Map<Date, Boolean>();
        Set<Date> targetDates = new Set<Date>();

        for (String d : rawDates) {
            Boolean isHalfDay = d.endsWith('HD');
            if (isHalfDay) d = d.replace('HD', '').trim();
            List<String> mmdd = d.split('/');
            if (mmdd.size() != 2) continue;

            Integer month = Integer.valueOf(mmdd[0]);
            Integer day = Integer.valueOf(mmdd[1]);
            Integer year = Integer.valueOf(yearStr);

            try {
                Date d1 = Date.newInstance(year, month, day);
                Date d2 = Date.newInstance(year - 1, month, day);
                Boolean found = false;
                for (Invoice_Line_Item__c ili : invoiceLines) {
                    if (ili.Service_Date__c == d1 || ili.Service_Date__c == d2) {
                        Date actual = ili.Service_Date__c;
                        targetDates.add(actual);
                        dateHalfDayMap.put(actual, isHalfDay);
                        found = true;
                        break;
                    }
                }
                if (!found) continue;
            } catch (Exception e) {
                continue;
            }
        }

        // Group Invoice Line Items by (OpportunityId + InvoiceId)
        Map<String, List<Invoice_Line_Item__c>> oppInvToILIs = new Map<String, List<Invoice_Line_Item__c>>();
        for (Invoice_Line_Item__c ili : invoiceLines) {
            String key = ili.Invoice__r.Opportunity__r.Id + '_' + ili.Invoice__r.Id;
            if (!oppInvToILIs.containsKey(key)) {
                oppInvToILIs.put(key, new List<Invoice_Line_Item__c>());
            }
            oppInvToILIs.get(key).add(ili);
        }

        // Check if any (Opportunity + Invoice) covers ALL dates
        Boolean singleMatch = false;
        for (String key : oppInvToILIs.keySet()) {
            List<Invoice_Line_Item__c> lines = oppInvToILIs.get(key);
            Set<Date> datesCovered = new Set<Date>();
            Decimal amount = 0;
            Id oppId;

            for (Invoice_Line_Item__c ili : lines) {
                if (targetDates.contains(ili.Service_Date__c)) {
                    Decimal rate = ili.Invoice__r.Opportunity__r.Consultant_Daily_Rate__c;
                    Decimal factor = dateHalfDayMap.containsKey(ili.Service_Date__c) && dateHalfDayMap.get(ili.Service_Date__c) ? 0.5 : 1;
                    amount += rate * factor;
                    datesCovered.add(ili.Service_Date__c);
                    oppId = ili.Invoice__r.Opportunity__r.Id;
                }
            }

            if (datesCovered.size() == targetDates.size()) {
                newPayrollOpportunities.add(new Payroll_Opportunity__c(
                    Payroll__c = payroll.Id,
                    Opportunity__c = oppId,
                    Amount__c = amount
                ));
                singleMatch = true;
                break;
            }
        }

        if (singleMatch) continue;

        // Fallback: Group by Opportunity only if no (opp+invoice) covered all
        Map<Id, List<Invoice_Line_Item__c>> oppToILIs = new Map<Id, List<Invoice_Line_Item__c>>();
        for (Invoice_Line_Item__c ili : invoiceLines) {
            Id oppId = ili.Invoice__r.Opportunity__r.Id;
            if (!oppToILIs.containsKey(oppId)) {
                oppToILIs.put(oppId, new List<Invoice_Line_Item__c>());
            }
            oppToILIs.get(oppId).add(ili);
        }

        for (Id oppId : oppToILIs.keySet()) {
            Set<Date> matchedDates = new Set<Date>();
            Decimal totalAmount = 0;
            for (Invoice_Line_Item__c ili : oppToILIs.get(oppId)) {
                Date dt = ili.Service_Date__c;
                if (targetDates.contains(dt) && !matchedDates.contains(dt)) {
                    Decimal rate = ili.Invoice__r.Opportunity__r.Consultant_Daily_Rate__c;
                    Decimal factor = dateHalfDayMap.containsKey(dt) && dateHalfDayMap.get(dt) ? 0.5 : 1;
                    totalAmount += rate * factor;
                    matchedDates.add(dt);
                }
            }
            if (!matchedDates.isEmpty()) {
                newPayrollOpportunities.add(new Payroll_Opportunity__c(
                    Payroll__c = payroll.Id,
                    Opportunity__c = oppId,
                    Amount__c = totalAmount
                ));
            }
        }
    }

    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}

/*
trigger PayrollTrigger on Payroll__c (before update, after insert) {
    
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    
    // Preload Invoice Line Items grouped by Purchase Order
    Map<String, List<Invoice_Line_Item__c>> purchaseOrderToInvoiceLineItemMap = new Map<String, List<Invoice_Line_Item__c>>();
    
    for (Invoice_Line_Item__c ili : [
        SELECT Id, Purchase_Order__c, Service_Date__c, 
               Invoice__r.Opportunity__r.Id, Invoice__r.Opportunity__r.Consultant_Daily_Rate__c
        FROM Invoice_Line_Item__c
        WHERE Purchase_Order__c != null
          AND Service_Date__c != null
          AND Invoice__r.Opportunity__r.Consultant_Daily_Rate__c != null
    ]) {
        if (!purchaseOrderToInvoiceLineItemMap.containsKey(ili.Purchase_Order__c)) {
            purchaseOrderToInvoiceLineItemMap.put(ili.Purchase_Order__c, new List<Invoice_Line_Item__c>());
        }
        purchaseOrderToInvoiceLineItemMap.get(ili.Purchase_Order__c).add(ili);
    }
    
    for (Payroll__c payroll : Trigger.new) {
        if (String.isBlank(payroll.Name)) continue;
        
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        
        if (payrollNameParts.size() < 4) continue;
        
        // Extract Purchase Order and Year
        String lastPart = payrollNameParts[payrollNameParts.size() - 1].trim();
        String yearStr;
        
        if (lastPart.endsWith(')') && lastPart.contains('(')) {
            Integer startIndex = lastPart.indexOf('(');
            Integer endIndex = lastPart.indexOf(')');
            yearStr = lastPart.substring(startIndex + 1, endIndex);
            lastPart = lastPart.substring(0, startIndex).trim();
        } else {
            yearStr = String.valueOf(payroll.CreatedDate.year());
        }
        
        String purchaseOrder = lastPart;
        String datesStr = payrollNameParts[2].trim();
        List<String> dateStrings = new List<String>();
        for (String datePart : datesStr.split(',')) {
            dateStrings.add(datePart.trim());
        }

        // Match Invoice Line Items
        if (purchaseOrderToInvoiceLineItemMap.containsKey(purchaseOrder)) {
            List<Invoice_Line_Item__c> iliList = purchaseOrderToInvoiceLineItemMap.get(purchaseOrder);

            // Map: Opportunity Id → List<Invoice_Line_Item__c> for this opp
            Map<Id, List<Invoice_Line_Item__c>> oppToILIs = new Map<Id, List<Invoice_Line_Item__c>>();

            for (Invoice_Line_Item__c ili : iliList) {
                Id oppId = ili.Invoice__r.Opportunity__r.Id;
                if (!oppToILIs.containsKey(oppId)) {
                    oppToILIs.put(oppId, new List<Invoice_Line_Item__c>());
                }
                oppToILIs.get(oppId).add(ili);
            }

            // Normalize payroll dates
            Map<Date, Boolean> dateHalfMap = new Map<Date, Boolean>();
            Set<Date> allTargetDates = new Set<Date>();

            for (String dateEntry : dateStrings) {
                Boolean isHalfDay = false;
                if (dateEntry.endsWith('HD')) {
                    isHalfDay = true;
                    dateEntry = dateEntry.substring(0, dateEntry.length() - 2).trim();
                }

                List<String> parts = dateEntry.split('/');
                if (parts.size() != 2) continue;

                Integer month = Integer.valueOf(parts[0]);
                Integer day = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(yearStr);

                try {
                    Date d1 = Date.newInstance(year, month, day);
                    Date d2 = Date.newInstance(year - 1, month, day);
                    Boolean found = false;

                    for (Invoice_Line_Item__c ili : iliList) {
                        if (ili.Service_Date__c == d1 || ili.Service_Date__c == d2) {
                            Date matchedDate = ili.Service_Date__c == d1 ? d1 : d2;
                            allTargetDates.add(matchedDate);
                            dateHalfMap.put(matchedDate, isHalfDay);
                            found = true;
                            break;
                        }
                    }

                    if (!found) continue;

                } catch (Exception e) {
                    continue;
                }
            }

            // Build one record per Opportunity for matching subset of dates
            for (Id oppId : oppToILIs.keySet()) {
                List<Invoice_Line_Item__c> iliForOpp = oppToILIs.get(oppId);
                Decimal localAmount = 0;
                Boolean atLeastOneMatch = false;
                Set<Date> matchedDates = new Set<Date>();

                for (Invoice_Line_Item__c ili : iliForOpp) {
                    Date sd = ili.Service_Date__c;
                    if (allTargetDates.contains(sd) && !matchedDates.contains(sd)) {
                        Decimal rate = ili.Invoice__r.Opportunity__r.Consultant_Daily_Rate__c;
                        Decimal factor = dateHalfMap.containsKey(sd) && dateHalfMap.get(sd) ? 0.5 : 1;
                        localAmount += rate * factor;
                        matchedDates.add(sd);
                        atLeastOneMatch = true;
                    }
                }

                if (atLeastOneMatch) {
                    Payroll_Opportunity__c newPO = new Payroll_Opportunity__c();
                    newPO.Payroll__c = payroll.Id;
                    newPO.Opportunity__c = oppId;
                    newPO.Amount__c = localAmount;
                    newPayrollOpportunities.add(newPO);
                }
            }
        }
    }
    
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/
/*
trigger PayrollTrigger on Payroll__c (before update, after insert) {
    
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    
    // Preload Invoice Line Items grouped by Purchase Order
    Map<String, List<Invoice_Line_Item__c>> purchaseOrderToInvoiceLineItemMap = new Map<String, List<Invoice_Line_Item__c>>();
    
    for (Invoice_Line_Item__c ili : [
        SELECT Id, Purchase_Order__c, Service_Date__c, 
               Invoice__r.Opportunity__r.Id, Invoice__r.Opportunity__r.Consultant_Daily_Rate__c
        FROM Invoice_Line_Item__c
        WHERE Purchase_Order__c != null
          AND Service_Date__c != null
          AND Invoice__r.Opportunity__r.Consultant_Daily_Rate__c != null
    ]) {
        if (!purchaseOrderToInvoiceLineItemMap.containsKey(ili.Purchase_Order__c)) {
            purchaseOrderToInvoiceLineItemMap.put(ili.Purchase_Order__c, new List<Invoice_Line_Item__c>());
        }
        purchaseOrderToInvoiceLineItemMap.get(ili.Purchase_Order__c).add(ili);
    }
    
    for (Payroll__c payroll : Trigger.new) {
        if (String.isBlank(payroll.Name)) continue;
        
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        
        if (payrollNameParts.size() < 4) continue;
        
        // Extract Purchase Order and Year
        String lastPart = payrollNameParts[payrollNameParts.size() - 1].trim();
        String yearStr;
        
        if (lastPart.endsWith(')') && lastPart.contains('(')) {
            Integer startIndex = lastPart.indexOf('(');
            Integer endIndex = lastPart.indexOf(')');
            yearStr = lastPart.substring(startIndex + 1, endIndex);
            lastPart = lastPart.substring(0, startIndex).trim();
        } else {
            yearStr = String.valueOf(payroll.CreatedDate.year());
        }
        
        String purchaseOrder = lastPart;
        String datesStr = payrollNameParts[2].trim();
        List<String> dateStrings = new List<String>();
        for (String datePart : datesStr.split(',')) {
            dateStrings.add(datePart.trim());
        }

        // Match Invoice Line Items
        if (purchaseOrderToInvoiceLineItemMap.containsKey(purchaseOrder)) {
            List<Invoice_Line_Item__c> iliList = purchaseOrderToInvoiceLineItemMap.get(purchaseOrder);

            // Group by OpportunityId -> (Date -> Rate)
            Map<Id, Map<Date, Decimal>> oppToDateRateMap = new Map<Id, Map<Date, Decimal>>();
            for (Invoice_Line_Item__c ili : iliList) {
                Id oppId = ili.Invoice__r.Opportunity__r.Id;
                Date serviceDate = ili.Service_Date__c;
                Decimal rate = ili.Invoice__r.Opportunity__r.Consultant_Daily_Rate__c;

                if (!oppToDateRateMap.containsKey(oppId)) {
                    oppToDateRateMap.put(oppId, new Map<Date, Decimal>());
                }
                oppToDateRateMap.get(oppId).put(serviceDate, rate);
            }

            // Convert dates from name to Date objects
            List<Date> targetDates = new List<Date>();
            Map<Date, Boolean> dateHalfMap = new Map<Date, Boolean>();

            for (String dateEntry : dateStrings) {
                Boolean isHalfDay = false;
                if (dateEntry.endsWith('HD')) {
                    isHalfDay = true;
                    dateEntry = dateEntry.substring(0, dateEntry.length() - 2).trim();
                }

                List<String> parts = dateEntry.split('/');
                if (parts.size() != 2) continue;

                Integer month = Integer.valueOf(parts[0]);
                Integer day = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(yearStr);

                try {
                    Date d1 = Date.newInstance(year, month, day);
                    Date d2 = Date.newInstance(year - 1, month, day);
                    Boolean foundInAny = false;

                    for (Invoice_Line_Item__c ili : iliList) {
                        if (ili.Service_Date__c == d1 || ili.Service_Date__c == d2) {
                            Date actual = ili.Service_Date__c == d1 ? d1 : d2;
                            targetDates.add(actual);
                            dateHalfMap.put(actual, isHalfDay);
                            foundInAny = true;
                            break;
                        }
                    }

                    if (!foundInAny) continue;

                } catch (Exception e) {
                    continue;
                }
            }

            // Find ONE Opportunity that has ALL dates
            Id finalOppId;
            Decimal totalAmount = 0;

            for (Id oppId : oppToDateRateMap.keySet()) {
                Map<Date, Decimal> dateToRate = oppToDateRateMap.get(oppId);
                Boolean allFound = true;
                Decimal localAmount = 0;

                for (Date dt : targetDates) {
                    if (dateToRate.containsKey(dt)) {
                        Decimal rate = dateToRate.get(dt);
                        Decimal factor = dateHalfMap.get(dt) ? 0.5 : 1;
                        localAmount += rate * factor;
                    } else {
                        allFound = false;
                        break;
                    }
                }

                if (allFound) {
                    finalOppId = oppId;
                    totalAmount = localAmount;
                    break; // Only one allowed
                }
            }

            // Create ONE Payroll_Opportunity__c
            if (finalOppId != null) {
                Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                newPayrollOpportunity.Payroll__c = payroll.Id;
                newPayrollOpportunity.Opportunity__c = finalOppId;
                newPayrollOpportunity.Amount__c = totalAmount;
                newPayrollOpportunities.add(newPayrollOpportunity);
            }
        }
    }
    
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/
/*
trigger PayrollTrigger on Payroll__c (before update, after insert) {
    
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    
    // Preload Invoice Line Items grouped by Purchase Order
    Map<String, List<Invoice_Line_Item__c>> purchaseOrderToInvoiceLineItemMap = new Map<String, List<Invoice_Line_Item__c>>();
    
    for (Invoice_Line_Item__c ili : [
        SELECT Id, Purchase_Order__c, Service_Date__c, 
               Invoice__r.Opportunity__r.Id, Invoice__r.Opportunity__r.Consultant_Daily_Rate__c
        FROM Invoice_Line_Item__c
        WHERE Purchase_Order__c != null
          AND Service_Date__c != null
          AND Invoice__r.Opportunity__r.Consultant_Daily_Rate__c != null
    ]) {
        if (!purchaseOrderToInvoiceLineItemMap.containsKey(ili.Purchase_Order__c)) {
            purchaseOrderToInvoiceLineItemMap.put(ili.Purchase_Order__c, new List<Invoice_Line_Item__c>());
        }
        purchaseOrderToInvoiceLineItemMap.get(ili.Purchase_Order__c).add(ili);
    }
    
    for (Payroll__c payroll : Trigger.new) {
        if (String.isBlank(payroll.Name)) continue; // Skip if no Name
        
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        
        if (payrollNameParts.size() < 4) continue; // Not enough parts
        
        // Step 1: Extract Purchase Order and Year
        String lastPart = payrollNameParts[payrollNameParts.size() - 1].trim();
        String yearStr;
        
        if (lastPart.endsWith(')') && lastPart.contains('(')) {
            Integer startIndex = lastPart.indexOf('(');
            Integer endIndex = lastPart.indexOf(')');
            yearStr = lastPart.substring(startIndex + 1, endIndex);
            lastPart = lastPart.substring(0, startIndex).trim();
        } else {
            yearStr = String.valueOf(payroll.CreatedDate.year());
        }
        
        String purchaseOrder = lastPart;
        
        // Step 2: Extract Dates
        String datesStr = payrollNameParts[2].trim();
        List<String> dateStrings = new List<String>();
        for (String datePart : datesStr.split(',')) {
            dateStrings.add(datePart.trim());
        }
        
        // Step 3: Match Invoice Line Items
        if (purchaseOrderToInvoiceLineItemMap.containsKey(purchaseOrder)) {
            List<Invoice_Line_Item__c> iliList = purchaseOrderToInvoiceLineItemMap.get(purchaseOrder);
            
            Map<Date, Invoice_Line_Item__c> serviceDateToILI = new Map<Date, Invoice_Line_Item__c>();
            for (Invoice_Line_Item__c ili : iliList) {
                serviceDateToILI.put(ili.Service_Date__c, ili);
            }
            
            Boolean allDatesMatched = true;
            Decimal totalAmount = 0;
            Set<Id> opportunityIds = new Set<Id>();
            
            for (String dateEntry : dateStrings) {
                Boolean isHalfDay = false;
                if (dateEntry.endsWith('HD')) {
                    isHalfDay = true;
                    dateEntry = dateEntry.substring(0, dateEntry.length() - 2).trim();
                }
                
                List<String> parts = dateEntry.split('/');
                if (parts.size() != 2) {
                    allDatesMatched = false;
                    break;
                }
                
                Integer month = Integer.valueOf(parts[0]);
                Integer day = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(yearStr);
                
                Date fullDate;
                Date altDate;
                
                try {
                    fullDate = Date.newInstance(year, month, day);
                    altDate = Date.newInstance(year - 1, month, day);
                } catch (Exception e) {
                    allDatesMatched = false;
                    break;
                }
                
                Invoice_Line_Item__c matchingILI;
                
                if (serviceDateToILI.containsKey(fullDate)) {
                    matchingILI = serviceDateToILI.get(fullDate);
                } else if (serviceDateToILI.containsKey(altDate)) {
                    matchingILI = serviceDateToILI.get(altDate);
                } else {
                    allDatesMatched = false;
                    break;
                }
                
                Decimal rate = matchingILI.Invoice__r.Opportunity__r.Consultant_Daily_Rate__c;
                Decimal factor = isHalfDay ? 0.5 : 1;
                totalAmount += rate * factor;
                opportunityIds.add(matchingILI.Invoice__r.Opportunity__r.Id);
            }
            
            // Step 4: Create Payroll Opportunities
            if (allDatesMatched && !opportunityIds.isEmpty()) {
                for (Id oppId : opportunityIds) {
                    Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                    newPayrollOpportunity.Payroll__c = payroll.Id;
                    newPayrollOpportunity.Opportunity__c = oppId;
                    newPayrollOpportunity.Amount__c = totalAmount;
                    newPayrollOpportunities.add(newPayrollOpportunity);
                }
            }
        }
    }
    
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/
/*
trigger PayrollTrigger on Payroll__c (before update, after insert) {
    // Create a list to store new Payroll Opportunity records
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    // Create a map to associate Purchase Orders with lists of Opportunity IDs
    Map<String, List<Id>> purchaseOrderToOpportunityMap = new Map<String, List<Id>>();
    
    // Retrieve a map of Opportunities with Purchase Orders and Daily Rates from the custom field
    Map<Id, Decimal> opportunityDailyRateMap = new Map<Id, Decimal>();
    
    // Build a map of opportunities with matching purchase orders
    for (Opportunity opp : [
        SELECT Id, Purchase_Order_Number__c, Consultant_Daily_Rate__c, Description 
        FROM Opportunity 
        WHERE Purchase_Order_Number__c != null 
        AND Consultant_Daily_Rate__c != null
    ]) {
        // Check if the Opportunity Description is not blank
        if (!String.isBlank(opp.Description)) {
            // Store Opportunity Daily Rates by Opportunity ID
            opportunityDailyRateMap.put(opp.Id, opp.Consultant_Daily_Rate__c);
            // Extract the Purchase Order from the Opportunity
            String purchaseOrder = opp.Purchase_Order_Number__c;
            // If the Purchase Order is not already in the map, create a new entry
            if (!purchaseOrderToOpportunityMap.containsKey(purchaseOrder)) {
                purchaseOrderToOpportunityMap.put(purchaseOrder, new List<Id>());
            }
            // Add the Opportunity ID to the Purchase Order's list of associated Opportunities
            purchaseOrderToOpportunityMap.get(purchaseOrder).add(opp.Id);
        }
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
                // Check if the last part ends with a year in parentheses
        String lastPart = payrollNameParts[payrollNameParts.size() - 1].trim();
        if (lastPart.endsWith(')') && lastPart.contains('(')) {
            // Remove the year if it exists
            lastPart = lastPart.substring(0, lastPart.indexOf('(')).trim();
        }
       // String purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
               // Set the purchase order to the modified or original last part
        String purchaseOrder = lastPart;
        
        // Extract dates from the Payroll Name field
        String dates = payrollNameParts[2].trim();
        
        // Find the last date in the list of dates
        String[] dateParts = dates.split(',');
        String lastDate = dateParts[dateParts.size() - 1].trim();
        
        // Check if the Purchase Order exists in the map
        if (purchaseOrderToOpportunityMap.containsKey(purchaseOrder)) {
            // Check if any of the dates from the Payroll Name are in the Opportunity Descriptions
            List<Id> opportunityIds = purchaseOrderToOpportunityMap.get(purchaseOrder);
            for (Id opportunityId : opportunityIds) {
                // Retrieve the Opportunity's Description
                
                Opportunity opp = [SELECT Description FROM Opportunity WHERE Id = :opportunityId];
                String opportunityDescription = opp.Description;
                // Check if the Opportunity Description is not blank
                
                if (String.isNotBlank(opportunityDescription)) {
                    Boolean matchFound = true;
                    Decimal totalAmount = 0; // Initialize the total amount as Decimal
                    
                    for (String date1 : dates.split(',')) {
                        date1 = date1.trim();
                        system.debug('date1   ' + date1);
                        // Check for "HD" in the date to handle half-days
                        if (date1.endsWith('HD')) {
                            date1 = date1.substring(0, date1.length() - 2).trim(); // Remove "HD" to get the date
                            // Calculate half-day amount (e.g., 0.5)
                            Decimal halfDayAmount = 0.5;
                            // Check if the Opportunity Description contains the date
                            if (!opportunityDescription.contains(date1)) {
                                matchFound = false;
                                break; // No need to check further for this opportunity
                            }
                            totalAmount += opportunityDailyRateMap.get(opportunityId) * halfDayAmount; // Increment the total amount by half-day
                        } else {
                            // Calculate full-day amount (e.g., 1)
                            Decimal fullDayAmount = 1;
                            
                            if (!opportunityDescription.contains(date1)) {
                                matchFound = false;
                                break; // No need to check further for this opportunity
                            }
                            totalAmount += opportunityDailyRateMap.get(opportunityId) * fullDayAmount; // Increment the total amount by full-day
                        }
                    }
                    
                    if (matchFound) {
                        // Create a new Payroll Opportunity record
                        Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                        newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
                        newPayrollOpportunity.Opportunity__c = opportunityId;
                        newPayrollOpportunity.Amount__c = totalAmount; // Assign the total amount
                        
                        newPayrollOpportunities.add(newPayrollOpportunity);
                    }
                }
            }
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/
/*
 // working with date like datess not match not create record
 trigger PayrollTrigger on Payroll__c (before update, after insert) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    Map<String, Id> purchaseOrderToOpportunityMap = new Map<String, Id>();
    
    // Retrieve a map of Opportunities with Purchase Orders and Daily Rates from the custom field
    Map<String, Id> opportunityPurchaseOrderMap = new Map<String, Id>();
    Map<Id, Decimal> opportunityDailyRateMap = new Map<Id, Decimal>();
    
    for (Opportunity opp : [
        SELECT Id, Purchase_Order_Number__c, Consultant_Daily_Rate__c, Description 
        FROM Opportunity 
        WHERE Purchase_Order_Number__c != null 
        AND Consultant_Daily_Rate__c != null
    ]) {
        if (!String.isBlank(opp.Description)) {
            opportunityPurchaseOrderMap.put(opp.Purchase_Order_Number__c, opp.Id);
            opportunityDailyRateMap.put(opp.Id, opp.Consultant_Daily_Rate__c);
        }
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        String purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
        
        // Extract dates from the Payroll Name field
        String dates = payrollNameParts[2].trim();
        
        // Find the last date in the list of dates
        String[] dateParts = dates.split(',');
        String lastDate = dateParts[dateParts.size() - 1].trim();
        
        // Check if the Purchase Order exists in the map
        if (opportunityPurchaseOrderMap.containsKey(purchaseOrder)) {
            // Check if any of the dates from the Payroll Name are in the Opportunity Description
            Id opportunityId = opportunityPurchaseOrderMap.get(purchaseOrder);
            Opportunity opp = [SELECT Description FROM Opportunity WHERE Id = :opportunityId];
            String opportunityDescription = opp.Description;
            
            if (String.isNotBlank(opportunityDescription)) {
                Boolean matchFound = false;
                Decimal totalAmount = 0; // Initialize the total amount as Decimal
                
                // Initialize a flag for each date
                Boolean foundInDescription = true;

                for (String date1 : dates.split(',')) {
                    date1 = date1.trim();
                    system.debug('date1   ' +date1);
                    // Check for "HD" in the date to handle half-days
                    if (date1.endsWith('HD')) {
                        date1 = date1.substring(0, date1.length() - 2).trim(); // Remove "HD" to get the date
                        // Calculate half-day amount (e.g., 0.5)
                        Decimal halfDayAmount = 0.5;
                        
                        if (opportunityDescription.contains(date1)) {
                             system.debug('date1   ' +date1);
                            totalAmount += opportunityDailyRateMap.get(opportunityId) * halfDayAmount; // Increment the total amount by half-day
                        } else {
                            foundInDescription = false;
                        }
                    } else {
                        // Calculate full-day amount (e.g., 1)
                        Decimal fullDayAmount = 1;
                        
                        if (opportunityDescription.contains(date1)) {
                             system.debug('date1   ' +date1);
                            totalAmount += opportunityDailyRateMap.get(opportunityId) * fullDayAmount; // Increment the total amount by full-day
                        } else {
                            foundInDescription = false;
                        }
                    }
                }
                
                // Set matchFound based on the flag
                matchFound = foundInDescription;

                if (matchFound) {
                    // Create a new Payroll Opportunity record
                    Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                    newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
                    newPayrollOpportunity.Opportunity__c = opportunityId;
                    newPayrollOpportunity.Amount__c = totalAmount; // Assign the total amount
                    
                    newPayrollOpportunities.add(newPayrollOpportunity);
                }
            }
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/


/*

trigger PayrollTrigger on Payroll__c (before update, after insert) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    Map<String, Id> purchaseOrderToOpportunityMap = new Map<String, Id>();
    
    // Retrieve a map of Opportunities with Purchase Orders and Daily Rates from the custom field
    Map<String, Id> opportunityPurchaseOrderMap = new Map<String, Id>();
    Map<Id, Decimal> opportunityDailyRateMap = new Map<Id, Decimal>();
    
    for (Opportunity opp : [
        SELECT Id, Purchase_Order_Number__c, Consultant_Daily_Rate__c, Description 
        FROM Opportunity 
        WHERE Purchase_Order_Number__c != null 
        AND Consultant_Daily_Rate__c != null
    ]) {
        if (!String.isBlank(opp.Description)) {
            opportunityPurchaseOrderMap.put(opp.Purchase_Order_Number__c, opp.Id);
            opportunityDailyRateMap.put(opp.Id, opp.Consultant_Daily_Rate__c);
        }
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        String purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
        
        // Extract dates from the Payroll Name field
        String dates = payrollNameParts[2].trim();
        
        // Find the last date in the list of dates
        String[] dateParts = dates.split(',');
        String lastDate = dateParts[dateParts.size() - 1].trim();
        
        // Check if the Purchase Order exists in the map
        if (opportunityPurchaseOrderMap.containsKey(purchaseOrder)) {
            // Check if any of the dates from the Payroll Name are in the Opportunity Description
            Id opportunityId = opportunityPurchaseOrderMap.get(purchaseOrder);
            Opportunity opp = [SELECT Description FROM Opportunity WHERE Id = :opportunityId];
            String opportunityDescription = opp.Description;
            
            if (String.isNotBlank(opportunityDescription)) {
                Boolean matchFound = false;
                Decimal totalAmount = 0; // Initialize the total amount as Decimal
                
                for (String date1 : dates.split(',')) {
                    date1 = date1.trim();
                    system.debug('date1   ' +date1);
                    // Check for "HD" in the date to handle half-days
                    if (date1.endsWith('HD')) {
                        date1 = date1.substring(0, date1.length() - 2).trim(); // Remove "HD" to get the date
                        // Calculate half-day amount (e.g., 0.5)
                        Decimal halfDayAmount = 0.5;
                        
                        if (opportunityDescription.contains(date1)) {
                             system.debug('date1   ' +date1);
                            matchFound = true;
                            totalAmount += opportunityDailyRateMap.get(opportunityId) * halfDayAmount; // Increment the total amount by half-day
                             system.debug('matchFound' +matchFound);
                        }
                    } else {
                        // Calculate full-day amount (e.g., 1)
                        Decimal fullDayAmount = 1;
                        
                        if (opportunityDescription.contains(date1)) {
                             system.debug('date1   ' +date1);
                            matchFound = true;
                            totalAmount += opportunityDailyRateMap.get(opportunityId) * fullDayAmount; // Increment the total amount by full-day
                            system.debug('matchFound' +matchFound);
                        }
                    }
                }
                
                if (matchFound) {
                    // Create a new Payroll Opportunity record
                    Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                    newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
                    newPayrollOpportunity.Opportunity__c = opportunityId;
                    newPayrollOpportunity.Amount__c = totalAmount; // Assign the total amount
                    
                    newPayrollOpportunities.add(newPayrollOpportunity);
                }
            }
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/


/*
// taking value where description have values
trigger PayrollTrigger on Payroll__c (before update, after insert) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    Map<String, Id> purchaseOrderToOpportunityMap = new Map<String, Id>();
    
    // Retrieve a map of Opportunities with Purchase Orders and Daily Rates from the custom field
    Map<String, Id> opportunityPurchaseOrderMap = new Map<String, Id>();
    Map<Id, Decimal> opportunityDailyRateMap = new Map<Id, Decimal>();
    
    for (Opportunity opp : [
        SELECT Id, Purchase_Order_Number__c, Consultant_Daily_Rate__c, Description 
        FROM Opportunity 
        WHERE Purchase_Order_Number__c != null 
        AND Consultant_Daily_Rate__c != null
    ]) {
        if (!String.isBlank(opp.Description)) {
            opportunityPurchaseOrderMap.put(opp.Purchase_Order_Number__c, opp.Id);
            opportunityDailyRateMap.put(opp.Id, opp.Consultant_Daily_Rate__c);
        }
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        String purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
        
        // Extract dates from the Payroll Name field
        String dates = payrollNameParts[2].trim();
        
        // Find the last date in the list of dates
        String[] dateParts = dates.split(',');
        String lastDate = dateParts[dateParts.size() - 1].trim();
        
        // Check if the Purchase Order exists in the map
        if (opportunityPurchaseOrderMap.containsKey(purchaseOrder)) {
            // Check if any of the dates from the Payroll Name are in the Opportunity Description
            Id opportunityId = opportunityPurchaseOrderMap.get(purchaseOrder);
            Opportunity opp = [SELECT Description FROM Opportunity WHERE Id = :opportunityId];
            String opportunityDescription = opp.Description;
            
            if (String.isNotBlank(opportunityDescription)) {
                Boolean matchFound = false;
                Decimal totalAmount = 0; // Initialize the total amount as Decimal
                
                for (String date1 : dates.split(',')) {
                    date1 = date1.trim();
                    
                    // Check for "HD" in the date to handle half-days
                    if (date1.endsWith('HD')) {
                        date1 = date1.substring(0, date1.length() - 2).trim(); // Remove "HD" to get the date
                        // Calculate half-day amount (e.g., 0.5)
                        Decimal halfDayAmount = 0.5;
                        
                        if (opportunityDescription.contains(date1)) {
                            matchFound = true;
                            totalAmount += opportunityDailyRateMap.get(opportunityId) * halfDayAmount; // Increment the total amount by half-day
                        }
                    } else {
                        // Calculate full-day amount (e.g., 1)
                        Decimal fullDayAmount = 1;
                        
                        if (opportunityDescription.contains(date1)) {
                            matchFound = true;
                            totalAmount += opportunityDailyRateMap.get(opportunityId) * fullDayAmount; // Increment the total amount by full-day
                        }
                    }
                }
                
                if (matchFound) {
                    // Create a new Payroll Opportunity record
                    Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                    newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
                    newPayrollOpportunity.Opportunity__c = opportunityId;
                    newPayrollOpportunity.Amount__c = totalAmount; // Assign the total amount
                    
                    newPayrollOpportunities.add(newPayrollOpportunity);
                }
            }
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/





/*
// also working with diffrent kind of payroll
trigger PayrollTrigger on Payroll__c (before update, after insert) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    Map<String, Id> purchaseOrderToOpportunityMap = new Map<String, Id>();
    
    // Retrieve a map of Opportunities with Purchase Orders and Daily Rates from the custom field
    Map<String, Id> opportunityPurchaseOrderMap = new Map<String, Id>();
    Map<Id, Decimal> opportunityDailyRateMap = new Map<Id, Decimal>();
    
    for (Opportunity opp : [SELECT Id, Purchase_Order_Number__c, Consultant_Daily_Rate__c, Description FROM Opportunity WHERE Purchase_Order_Number__c != null AND Consultant_Daily_Rate__c != null]) {
        opportunityPurchaseOrderMap.put(opp.Purchase_Order_Number__c, opp.Id);
        opportunityDailyRateMap.put(opp.Id, opp.Consultant_Daily_Rate__c);
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        String purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
        system.debug('purchaseOrder' +purchaseOrder);
        system.debug('opportunityPurchaseOrderMap' +opportunityPurchaseOrderMap);
        // Extract dates from the Payroll Name field
        String dates = payrollNameParts[2].trim();
        system.debug('dates' +dates);
        
        // Find the last date in the list of dates
        String[] dateParts = dates.split(',');
        String lastDate = dateParts[dateParts.size() - 1].trim();
        
        // Check if the Purchase Order exists in the map
        if (opportunityPurchaseOrderMap.containsKey(purchaseOrder)) {
            system.debug('inside if');
            // Check if any of the dates from the Payroll Name are in the Opportunity Description
            Id opportunityId = opportunityPurchaseOrderMap.get(purchaseOrder);
            system.debug('opportunityId' +opportunityId);
            Opportunity opp = [SELECT Description FROM Opportunity WHERE Id = :opportunityId];
            String opportunityDescription = opp.Description;
            
            Boolean matchFound = false;
            Decimal totalAmount = 0; // Initialize the total amount as Decimal
            
            for (String date1 : dates.split(',')) {
                date1 = date1.trim();
                
                // Check for "HD" in the date to handle half-days
                if (date1.endsWith('HD')) {
                    date1 = date1.substring(0, date1.length() - 2).trim(); // Remove "HD" to get the date
                    // Calculate half-day amount (e.g., 0.5)
                    Decimal halfDayAmount = 0.5;
                    
                    if (opportunityDescription != null && opportunityDescription.contains(date1)) {
                        matchFound = true;
                        totalAmount += opportunityDailyRateMap.get(opportunityId) * halfDayAmount; // Increment the total amount by half-day
                    }
                } else {
                    // Calculate full-day amount (e.g., 1)
                    Decimal fullDayAmount = 1;
                    
                    if (opportunityDescription != null && opportunityDescription.contains(date1)) {
                        matchFound = true;
                        totalAmount += opportunityDailyRateMap.get(opportunityId) * fullDayAmount; // Increment the total amount by full-day
                        system.debug('totalAmount');
                    }
                }
            }
            system.debug('matchFound' +matchFound);
            if (matchFound) {
                system.debug('matchFound');
                // Create a new Payroll Opportunity record
                Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
                newPayrollOpportunity.Opportunity__c = opportunityId;
                newPayrollOpportunity.Amount__c = totalAmount; // Assign the total amount
                
                newPayrollOpportunities.add(newPayrollOpportunity);
            }
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/




/*trigger PayrollTrigger on Payroll__c (before insert, before update) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    Map<String, Id> purchaseOrderToOpportunityMap = new Map<String, Id>();
    
    // Retrieve a map of Opportunities with Purchase Orders and Daily Rates from the custom field
    Map<String, Id> opportunityPurchaseOrderMap = new Map<String, Id>();
    Map<Id, Decimal> opportunityDailyRateMap = new Map<Id, Decimal>();
    
    for (Opportunity opp : [SELECT Id, Purchase_Order_Number__c, Consultant_Daily_Rate__c, Description FROM Opportunity WHERE Purchase_Order_Number__c != null AND Consultant_Daily_Rate__c != null]) {
        opportunityPurchaseOrderMap.put(opp.Purchase_Order_Number__c, opp.Id);
        opportunityDailyRateMap.put(opp.Id, opp.Consultant_Daily_Rate__c);
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        
        String purchaseOrder = '';
        String dates = payrollNameParts[2].trim();
        
        // Check if payroll.Name contains "Check No"
        if (payrollName.contains('Check No')) {
            // If it contains "Check No," set purchaseOrder to "Check No. 495107"
            purchaseOrder = 'Check No. 495107';
        } else {
            // Otherwise, extract the purchase order from the name
            purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
        }
        
        // Check if the Purchase Order exists in the map
        if (opportunityPurchaseOrderMap.containsKey(purchaseOrder)) {
            // Check if any of the dates from the Payroll Name are in the Opportunity Description
            Id opportunityId = opportunityPurchaseOrderMap.get(purchaseOrder);
            Opportunity opp = [SELECT Description FROM Opportunity WHERE Id = :opportunityId];
            String opportunityDescription = opp.Description;
            
            Boolean matchFound = false;
            Decimal totalAmount = 0; // Initialize the total amount as Decimal
            
            for (String date1 : dates.split(',')) {
                date1 = date1.trim();
                
                // Check for "HD" in the date to handle half-days
                if (date1.endsWith('HD')) {
                    date1 = date1.substring(0, date1.length() - 2).trim(); // Remove "HD" to get the date
                    // Calculate half-day amount (e.g., 0.5)
                    Decimal halfDayAmount = 0.5;
                    
                    if (opportunityDescription.contains(date1)) {
                        matchFound = true;
                        totalAmount += opportunityDailyRateMap.get(opportunityId) * halfDayAmount; // Increment the total amount by half-day
                    }
                } else {
                    // Calculate full-day amount (e.g., 1)
                    Decimal fullDayAmount = 1;
                    
                    if (opportunityDescription.contains(date1)) {
                        matchFound = true;
                        totalAmount += opportunityDailyRateMap.get(opportunityId) * fullDayAmount; // Increment the total amount by full-day
                    }
                }
            }
            
            if (matchFound) {
                // Create a new Payroll Opportunity record
                Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
                newPayrollOpportunity.Opportunity__c = opportunityId;
                newPayrollOpportunity.Amount__c = totalAmount; // Assign the total amount
                
                newPayrollOpportunities.add(newPayrollOpportunity);
            }
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/


/*
// working with half day
trigger PayrollTrigger on Payroll__c (before insert, before update) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    Map<String, Id> purchaseOrderToOpportunityMap = new Map<String, Id>();
    
    // Retrieve a map of Opportunities with Purchase Orders and Daily Rates from the custom field
    Map<String, Id> opportunityPurchaseOrderMap = new Map<String, Id>();
    Map<Id, Decimal> opportunityDailyRateMap = new Map<Id, Decimal>();
    
    for (Opportunity opp : [SELECT Id, Purchase_Order_Number__c, Consultant_Daily_Rate__c, Description FROM Opportunity WHERE Purchase_Order_Number__c != null AND Consultant_Daily_Rate__c != null]) {
        opportunityPurchaseOrderMap.put(opp.Purchase_Order_Number__c, opp.Id);
        opportunityDailyRateMap.put(opp.Id, opp.Consultant_Daily_Rate__c);
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        String purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
        
        // Extract dates from the Payroll Name field
        String dates = payrollNameParts[2].trim();
        
        // Check if the Purchase Order exists in the map
        if (opportunityPurchaseOrderMap.containsKey(purchaseOrder)) {
            // Check if any of the dates from the Payroll Name are in the Opportunity Description
            Id opportunityId = opportunityPurchaseOrderMap.get(purchaseOrder);
            Opportunity opp = [SELECT Description FROM Opportunity WHERE Id = :opportunityId];
            String opportunityDescription = opp.Description;
            
            Boolean matchFound = false;
            Decimal totalAmount = 0; // Initialize the total amount as Decimal
            
            for (String date1 : dates.split(',')) {
                date1 = date1.trim();
                
                // Check for "HD" in the date to handle half-days
                if (date1.endsWith('HD')) {
                    date1 = date1.substring(0, date1.length() - 2).trim(); // Remove "HD" to get the date
                    // Calculate half-day amount (e.g., 0.5)
                    Decimal halfDayAmount = 0.5;
                    
                    if (opportunityDescription.contains(date1)) {
                        matchFound = true;
                        totalAmount += opportunityDailyRateMap.get(opportunityId) * halfDayAmount; // Increment the total amount by half-day
                    }
                } else {
                    // Calculate full-day amount (e.g., 1)
                    Decimal fullDayAmount = 1;
                    
                    if (opportunityDescription.contains(date1)) {
                        matchFound = true;
                        totalAmount += opportunityDailyRateMap.get(opportunityId) * fullDayAmount; // Increment the total amount by full-day
                    }
                }
            }
            
            if (matchFound) {
                // Create a new Payroll Opportunity record
                Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
                newPayrollOpportunity.Opportunity__c = opportunityId;
                newPayrollOpportunity.Amount__c = totalAmount; // Assign the total amount
                
                newPayrollOpportunities.add(newPayrollOpportunity);
            }
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/

/*
// wokring with amount
trigger PayrollTrigger on Payroll__c (before insert, before update) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    Map<String, Id> purchaseOrderToOpportunityMap = new Map<String, Id>();
    
    // Retrieve a map of Opportunities with Purchase Orders and Daily Rates from the custom field
    Map<String, Id> opportunityPurchaseOrderMap = new Map<String, Id>();
    Map<Id, Decimal> opportunityDailyRateMap = new Map<Id, Decimal>();
    
    for (Opportunity opp : [SELECT Id, Purchase_Order_Number__c, Consultant_Daily_Rate__c, Description FROM Opportunity WHERE Purchase_Order_Number__c != null AND Consultant_Daily_Rate__c != null]) {
        opportunityPurchaseOrderMap.put(opp.Purchase_Order_Number__c, opp.Id);
        opportunityDailyRateMap.put(opp.Id, opp.Consultant_Daily_Rate__c);
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        String purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
        
        // Extract dates from the Payroll Name field
        String dates = payrollNameParts[2].trim();
        
        // Check if the Purchase Order exists in the map
        if (opportunityPurchaseOrderMap.containsKey(purchaseOrder)) {
            // Check if any of the dates from the Payroll Name are in the Opportunity Description
            Id opportunityId = opportunityPurchaseOrderMap.get(purchaseOrder);
            Opportunity opp = [SELECT Description FROM Opportunity WHERE Id = :opportunityId];
            String opportunityDescription = opp.Description;
            
            Boolean matchFound = false;
            Integer numberOfDates = 0; // Initialize the number of dates to 0
            
            for (String date1 : dates.split(',')) {
                date1 = date1.trim();
                if (opportunityDescription.contains(date1)) {
                    matchFound = true;
                    numberOfDates++; // Increment the number of dates
                }
            }
            
            if (matchFound) {
                // Create a new Payroll Opportunity record
                Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
                newPayrollOpportunity.Opportunity__c = opportunityId;
                
                // Calculate the Amount__c based on the number of dates and the daily rate
                if (opportunityDailyRateMap.containsKey(opportunityId)) {
                    Decimal dailyRate = opportunityDailyRateMap.get(opportunityId);
                    Decimal amount = dailyRate * numberOfDates;
                    newPayrollOpportunity.Amount__c = amount;
                }
                
                newPayrollOpportunities.add(newPayrollOpportunity);
            }
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/


/*
// working without Amount__c  
  trigger PayrollTrigger on Payroll__c (before insert, before update) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    Map<String, Id> purchaseOrderToOpportunityMap = new Map<String, Id>();
    
    // Retrieve a map of Opportunities with Purchase Orders from the custom field
    Map<String, Id> opportunityPurchaseOrderMap = new Map<String, Id>();
    for (Opportunity opp : [SELECT Id, Purchase_Order_Number__c, Description,Consultant_Daily_Rate__c FROM Opportunity WHERE Purchase_Order_Number__c != null]) {
        opportunityPurchaseOrderMap.put(opp.Purchase_Order_Number__c, opp.Id);
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
     //   String payrollName = payroll.Name;
       // String[] payrollNameParts = payrollName.split('-');
      //  String purchaseOrder = payrollNameParts[4].trim(); // Assuming the Purchase Order is always at index 4
              String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        String purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
        
        // Extract dates from the Payroll Name field
        String dates = payrollNameParts[2].trim();
        
        // Check if the Purchase Order exists in the map
        if (opportunityPurchaseOrderMap.containsKey(purchaseOrder)) {
            // Check if any of the dates from the Payroll Name are in the Opportunity Description
            Id opportunityId = opportunityPurchaseOrderMap.get(purchaseOrder);
            Opportunity opp = [SELECT Description FROM Opportunity WHERE Id = :opportunityId];
            String opportunityDescription = opp.Description;
            
            Boolean matchFound = false;
            for (String date1 : dates.split(',')) {
                date1 = date1.trim();
                if (opportunityDescription.contains(date1)) {
                    matchFound = true;
                    break;
                }
            }
            
            if (matchFound) {
                // Create a new Payroll Opportunity record
                Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
                newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
                newPayrollOpportunity.Opportunity__c = opportunityId;
                newPayrollOpportunities.add(newPayrollOpportunity);
            }
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/


/*
  trigger PayrollTrigger on Payroll__c (before insert, before update) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    Map<String, Id> purchaseOrderToOpportunityMap = new Map<String, Id>();
    
    // Retrieve a map of Opportunities with Purchase Orders from custom field
    Map<String, Id> opportunityPurchaseOrderMap = new Map<String, Id>();
    for (Opportunity opp : [SELECT Id, Purchase_Order_Number__c FROM Opportunity WHERE Purchase_Order_Number__c != null]) {
        opportunityPurchaseOrderMap.put(opp.Purchase_Order_Number__c, opp.Id);
    }
    
    for (Payroll__c payroll : Trigger.new) {
        // Extract the Purchase Order from the Payroll Name field
        String payrollName = payroll.Name;
        String[] payrollNameParts = payrollName.split('-');
        String purchaseOrder = payrollNameParts[payrollNameParts.size() - 1].trim();
        
        // Check if the Purchase Order exists in the map
        if (opportunityPurchaseOrderMap.containsKey(purchaseOrder)) {
            // Create a new Payroll Opportunity record
            Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
            newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
            newPayrollOpportunity.Opportunity__c = opportunityPurchaseOrderMap.get(purchaseOrder);
            newPayrollOpportunities.add(newPayrollOpportunity);
        }
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}

*/

/*trigger PayrollTrigger on Payroll__c (before insert, before update) {
    List<Payroll_Opportunity__c> newPayrollOpportunities = new List<Payroll_Opportunity__c>();
    
    for (Payroll__c payroll : Trigger.new) {
        // Create a new Payroll Opportunity record
        Payroll_Opportunity__c newPayrollOpportunity = new Payroll_Opportunity__c();
        newPayrollOpportunity.Payroll__c = payroll.Id; // Set Payroll as a lookup
        newPayrollOpportunities.add(newPayrollOpportunity);
    }
    
    // Insert new Payroll Opportunity records
    if (!newPayrollOpportunities.isEmpty()) {
        insert newPayrollOpportunities;
    }
}
*/