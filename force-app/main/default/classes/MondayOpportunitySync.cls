public class MondayOpportunitySync implements Queueable, Database.AllowsCallouts {
    public Set<Id> accountIds;
    private static final String BOARD_ID = '9088771371';
    private static final String PRINCIPAL_EMAIL_COLUMN_ID = 'text_mkqzraew';
    private static final String AMOUNT_COLUMN_ID = 'numeric_mkqzrjvm';
    private static final String DATE_COLUMN_ID = 'date_mkqzh0eh';
    private static final String STAGE_COLUMN_ID = 'dropdown_mkr3qdxr';
    private static final String PARTNER_COLUMN_ID = 'date_mkr550m3';
    private static final String SPENT_ALL_TIME_COLUMN_ID = 'numeric_mkqzfvwh';
    private static final String TOTAL_POS_GENERATED_COLUMN_ID = 'numeric_mkqzf6yv';
    private static final String PENDING_SY_25_26_COLUMN_ID = 'numeric_mkqz2ef2';
    private static final String WOS_NOT_CONVERTED_COLUMN_ID = 'numeric_mkqzg5gc';
    private static final String OPPORTUNITY_SY_25_26_COLUMN_ID = 'numeric_mkqz8qmg';
    private static final String SERVICES_SY_24_25_COLUMN_ID = 'dropdown_mkr3mj99';
    private static final String SERVICES_SY_25_26_COLUMN_ID = 'dropdown_mkqz7gyf';
    private static final String PRINCIPAL_NAME_COLUMN_ID = 'text_mkqqp5d3';
    private static final String OPPS_SHEET_COLUMN_ID = 'link_mkqqddsb';
    private static final String OPPS_DISTRICT_COLUMN_ID = 'text_mkqzspp3';
    private static final String ADDRESS_COLUMN_ID = 'location_mkresrmv';
    private static final String STATE_COLUMN_ID = 'color_mkrhg2m1';
    private static final String DBN_COLUMN_ID = 'text_mkrsncpn';
    
    // SubItem Columns - 
    private static final String SUBITEM_AMOUNT_COLUMN_ID = 'numeric_mkqzrjvm';
    private static final String SUBITEM_STAGE_COLUMN_ID = 'status';
    private static final String SUBITEM_DATE_COLUMN_ID = 'date_mkqzh0eh'; 
    private static final String SUBITEM_YEAR_COLUMN_ID = 'text_mkr4w4wv';
    private static final String SUBITEM_SALESPERSON_COLUMN_ID = 'text_mkr46qpj';
    private static final String SUBITEM_PARTNER_COLUMN_ID = 'text_mkqzfq6b';
    private static final String SUBITEM_FIRST_PURCHASE_COLUMN_ID = 'date_mkrdh304';
    private static final String SUBITEM_DAYS_REMAINING_COLUMN_ID = 'text_mkrbx4z3';
    private static final String SUBITEM_DATE_WORK_ORDER_SENT = 'text_mkzzs6kw';
    
    // Mapping for Product Services
    public static final Map<String, String> PRODUCT_SERVICE_MAPPING = new Map<String, String>{
        'Data Dashboard ELA - Coaching' => 'Data Dashboard',
            'Data Dashboard Math - Coaching' => 'Data Dashboard',
            'Data Dashboard' => 'Data Dashboard',
            'Data Coaching' => 'Other Coaching',
            'Leadership Coaching' => 'Other Coaching',
            'Other Coaching' => 'Other Coaching',
            'Science Coaching' => 'Other Coaching',
            'Social Studies Coaching' => 'Other Coaching',
            'Special Education Coaching' => 'Other Coaching',
            'Branding and Merchandise' => 'Branding'
            };
                
                public MondayOpportunitySync(Set<Id> accountIds) {
                    this.accountIds = accountIds;
                    System.debug('MondayOpportunitySync initialized with accountIds: ' + accountIds);
                }
    
    public void execute(QueueableContext context) {
        System.debug('Starting execute method');
        try {
            Set<String> predefinedSubitems = new Set<String>{
                'App','Data Dashboard','Website',
                    'Online CTLE Asynchronous Courses',
                    'Photography', 'Promo Video', 'ELA Coaching','Math Coaching','Other Coaching','Branding'
                    };
                        System.debug('Predefined subitems loaded: ' + predefinedSubitems.size() + ' items');
            
            System.debug('Querying accounts with opportunities');
            List<Account> accounts = [
                SELECT Id, DBN__c, Name, Principal__c, Principal_Email__c, Dashboard_DBN_URL__c,App_POCs__c,Branding_POCs__c ,Coaching_POCs__c,
                Data_PoC_Emails__c ,Online_CTLE_Course_POCs__c , Photo_Video_POCs__c ,Special_Project_POCs__c ,Website_POCs__c,
                BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                (SELECT Id, Name, School_Year__c, Type, StageName, Amount,Product_Service_End_Date__c,Salesperson__c ,Consultant_days_remaining__c ,
                 CloseDate, District_of_school__c, Product_Service__c, Work_Order_Sent_Date__c, LastModifiedDate
                 FROM Opportunities)
                FROM Account
                WHERE Id IN :accountIds
            ];
            System.debug('Found ' + accounts.size() + ' accounts to process');
            
            System.debug('Getting existing DBNs from Monday');
            Set<String> existingDbns = getExistingDBNsFromMonday();
            System.debug('Found ' + existingDbns.size() + 'existing DBNs in Monday');
            
            for (Account acc : accounts) {
                System.debug('Processing account: ' + acc.Name + ' (DBN: ' + acc.DBN__c + ')');
                try {
                    processAccount(acc, existingDbns, predefinedSubitems);
                } catch (Exception e) {
                    System.debug('Error processing account ' + acc.Name + ': ' + e.getMessage() + ' at line ' + e.getLineNumber());
                    System.debug('Stack trace: ' + e.getStackTraceString());
                }
            }
            System.debug('Finished processing all accounts');
        } catch (Exception e) {
            System.debug('Error in execute method: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    public class AddressFormatter {
        public Map<String, Object> formatBillingAddress(Account acc) {
            if (acc.BillingStreet == null || acc.BillingCity == null || acc.BillingState == null || acc.BillingPostalCode == null) {
                return new Map<String, Object>{
                    'address' => '',
                        'lat' => 0,
                        'lng' => 0
                        };
                            }
            String address = String.format('{0},{1},{2},{3}', new List<String>{acc.BillingStreet, acc.BillingState, acc.BillingPostalCode, acc.BillingCity});
            return new Map<String, Object>{
                'address' => address,
                    'lat' => 0,
                    'lng' => 0
                    };
                        }
    }
    
    // This i have added for services 24-25 and 25-26
    public String adjustSchoolYearBasedOnEndDate(Date endDate) {
    if (endDate == null) {
        return null;
    }

    Integer endYear = endDate.year();
    String startYear = String.valueOf(endYear - 1).substring(2);
    String endYearStr = String.valueOf(endYear).substring(2);

    return startYear + '-' + endYearStr;
}

    public void processAccount(Account acc, Set<String> existingDbns, Set<String> predefinedSubitems) {
        System.debug('Starting processAccount for ' + acc.Name);
        String dbn = acc.DBN__c;
        String principalEmail = acc.Principal_Email__c;
        String principalName = acc.Principal__c;
        String oppsSheet = acc.Dashboard_DBN_URL__c;
        
        // Make a formatting of billing address
        AddressFormatter addressFormatter = new AddressFormatter();
        Map<String, Object> addressInfo = addressFormatter.formatBillingAddress(acc);
        String address = (String) addressInfo.get('address');
        Double lat = (Double) addressInfo.get('lat');
        Double lng = (Double) addressInfo.get('lng');
        
        if (String.isBlank(dbn) || String.isBlank(principalEmail)) {
            System.debug('Skipping account - missing DBN or Principal Email. DBN: ' + dbn + ', Email: ' + principalEmail);
            return;
        }
        
        // Check if all opportunities are closed
        Boolean allOpportunitiesClosed = true;
        for (Opportunity opp : acc.Opportunities) {
            if (opp.StageName != 'Closed') {
                allOpportunitiesClosed = false;
                break;
            }
        }
        
        if (allOpportunitiesClosed) {
            System.debug('All opportunities are closed for DBN: ' + dbn);
            if (existingDbns.contains(dbn)) {
                System.debug('Deleting item from Monday board for DBN: ' + dbn);
                deleteMondayItem(dbn);
            }
            return;
        }
        
        System.debug('Calculating account metrics');
        Date earliestWorkOrderSentDate = findEarliestWorkOrderSentDate(acc.Opportunities);
        Double totalAmount = calculateTotalAmount(acc.Opportunities);
        Double totalPOsGenerated = calculateTotalPOsGenerated(acc.Opportunities);
        Double totalPendingSY2526 = calculateTotalPendingSY2526(acc.Opportunities);
        Double totalWOsNotConverted = calculateTotalWOsNotConverted(acc.Opportunities);
        Double totalOpportunitySY2526 = calculateTotalOpportunitySY2526(acc.Opportunities);
        
        System.debug('Metrics calculated - Amount: ' + totalAmount + ', POs: ' + totalPOsGenerated +
                     ', Pending: ' + totalPendingSY2526 + ', WOs Not Converted: ' + totalWOsNotConverted +
                     ', Opportunity: ' + totalOpportunitySY2526);
        
        Set<String> productServicesSY2425 = collectProductServicesForSY(acc.Opportunities, '24-25');
        Set<String> productServicesSY2526 = collectProductServicesForSY(acc.Opportunities, '25-26');
        System.debug('Product Services - SY24-25: ' + productServicesSY2425 + ', SY25-26: ' + productServicesSY2526);
        
        // Fetch the district from the first opportunity (assuming all opportunities have the same district)
        String district = acc.Opportunities.isEmpty() ? '' : acc.Opportunities[0].District_of_school__c;
        
        String mainItemId;
        if (existingDbns.contains(dbn)) {
            System.debug('Account exists in Monday, getting item ID');
            mainItemId = getMondayItemIdByDBN(dbn);
            System.debug('Monday item ID for DBN ' + dbn + ': ' + mainItemId);
            if (String.isNotBlank(mainItemId)) {
                System.debug('Updating existing Monday item');
                updateMondayItem(mainItemId, principalEmail,dbn, earliestWorkOrderSentDate, totalAmount, totalPOsGenerated,
                                 totalPendingSY2526, totalWOsNotConverted, totalOpportunitySY2526,
                                 productServicesSY2425, productServicesSY2526, principalName, oppsSheet, district,address, lat ,lng,acc.BillingState);
            }
        } else {
            System.debug('Creating new Monday item for DBN: ' + dbn);
            Map<String, Object> mainCols = new Map<String, Object>{
                PRINCIPAL_EMAIL_COLUMN_ID => principalEmail,
                    DBN_COLUMN_ID => dbn,
                    PARTNER_COLUMN_ID => earliestWorkOrderSentDate != null ? formatDate(earliestWorkOrderSentDate) : null,
                        SPENT_ALL_TIME_COLUMN_ID => totalAmount,
                        TOTAL_POS_GENERATED_COLUMN_ID => totalPOsGenerated,
                        PENDING_SY_25_26_COLUMN_ID => totalPendingSY2526,
                        WOS_NOT_CONVERTED_COLUMN_ID => totalWOsNotConverted,
                        OPPORTUNITY_SY_25_26_COLUMN_ID => totalOpportunitySY2526,
                        SERVICES_SY_24_25_COLUMN_ID => String.join(new List<String>(productServicesSY2425), ', '),
                        SERVICES_SY_25_26_COLUMN_ID => String.join(new List<String>(productServicesSY2526), ', '),
                        PRINCIPAL_NAME_COLUMN_ID => principalName,
                        OPPS_SHEET_COLUMN_ID => oppsSheet,
                        OPPS_DISTRICT_COLUMN_ID  => district, // Include District column
                        ADDRESS_COLUMN_ID => new Map<String , Object>{
                            'address' => address,
                                'lat' => lat,
                                'lng' => lng
                                },
                        STATE_COLUMN_ID => acc.BillingState
            };
                System.debug('Column values for new item: ' + mainCols);
            mainItemId = createMondayItem(dbn, mainCols);
            System.debug('Created item with ID: ' + mainItemId);
            
            if (String.isNotBlank(mainItemId)) {
                System.debug('Creating predefined subitems');
                createPredefinedSubitems(mainItemId, predefinedSubitems);
            }
        }
        
        if (String.isBlank(mainItemId)) {
            System.debug('No main item ID, skipping opportunity processing');
            return;
        }
        
        System.debug('Processing opportunities for account');
        processOpportunities(acc, mainItemId, predefinedSubitems);
        
        // Fetch existing subitem names for the main item
        Set<String> existingSubitemNames = getExistingSubitemNames(mainItemId);
        
        // Map POCs from Account fields to subitems
        Map<String, String> subitemPOCs = new Map<String, String>{
            'App' => acc.App_POCs__c,
                'Branding' => acc.Branding_POCs__c,
                'Other Coaching' => acc.Coaching_POCs__c,
                'Online CTLE Asynchronous Courses' => acc.Online_CTLE_Course_POCs__c,
                'Photography' => acc.Photo_Video_POCs__c,
                'Website' => acc.Website_POCs__c,
                'Data Dashboard' => acc.Data_PoC_Emails__c
                };
                    
                    // Update subitems with POCs
                    for (String subitem : subitemPOCs.keySet()) {
                        if (predefinedSubitems.contains(subitem) || existingSubitemNames.contains(subitem)) {
                            Map<String, Object> columnValues = new Map<String, Object>{
                                'partner_pocs' => subitemPOCs.get(subitem)
                                    };
                                        updateMondaySubitem(mainItemId, subitem, columnValues);
                        }
                    }
        
        System.debug('Finished processing account ' + acc.Name);
    }
    
    // Method to delete an item from the Monday board
    private void deleteMondayItem(String dbn) {
        System.debug('Deleting Monday item for DBN: ' + dbn);
        String itemId = getMondayItemIdByDBN(dbn);
        if (String.isNotBlank(itemId)) {
            String mutation = 'mutation { delete_item (item_id: ' + itemId + ') { id } }';
            System.debug('Mutation: ' + mutation);
            HttpResponse res = sendMondayRequest(mutation);
            System.debug('Monday API response status: ' + res.getStatusCode());
            System.debug('Response body: ' + res.getBody());
        } else {
            System.debug('No item ID found for DBN: ' + dbn);
        }
    }
    
    public Map<String, Object> formatLinkColumnValue(String url, String text) {
        if (String.isBlank(url)) {
            System.debug('URL is blank, returning null for link column');
            return null;
        }
        
        // Default text to URL if not provided
        if (String.isBlank(text)) {
            text = url;
        }
        
        Map<String, Object> linkValue = new Map<String, Object>{
            'url' => url,
                'text' => text
                };
                    
                    System.debug('Formatted link column value: ' + linkValue);
        return linkValue;
    }
    
    public Date findEarliestWorkOrderSentDate(List<Opportunity> opportunities) {
        System.debug('Finding earliest work order sent date from ' + opportunities.size() + ' opportunities');
        Date earliestWorkOrderSentDate = null;
        for (Opportunity opp : opportunities) {
            if (opp.Work_Order_Sent_Date__c != null && (earliestWorkOrderSentDate == null || opp.Work_Order_Sent_Date__c < earliestWorkOrderSentDate)) {
                earliestWorkOrderSentDate = opp.Work_Order_Sent_Date__c;
            }
        }
        System.debug('Earliest work order sent date: ' + earliestWorkOrderSentDate);
        return earliestWorkOrderSentDate;
    }
    
    public Double calculateTotalAmount(List<Opportunity> opportunities) {
        System.debug('Calculating total amount from ' + opportunities.size() + ' opportunities');
        Double totalAmount = 0.0;
        for (Opportunity opp : opportunities) {
            if (opp.Amount != null && opp.StageName != 'Pending' && opp.StageName != 'Closed' && opp.StageName != 'Deleted' && opp.StageName != 'Deferred Budget 25-26' && opp.StageName != 'Deferred July 2024' && opp.StageName != 'Awaiting Renewal Confirmation') {
                totalAmount += opp.Amount;
            }
        }
        System.debug('Total amount calculated: ' + totalAmount);
        return totalAmount;
    }
    
    public Double calculateTotalPOsGenerated(List<Opportunity> opportunities) {
        System.debug('Calculating total POs generated from ' + opportunities.size() + ' opportunities');
        Double totalPOsGenerated = 0.0;
        for (Opportunity opp : opportunities) {
            if (opp.StageName != null && (opp.StageName == 'Fully Invoiced' || opp.StageName == 'Fully Paid' || opp.StageName == 'Purchase Order Generated' || opp.StageName == 'Partially Invoiced' || opp.StageName == 'Partially Paid') && opp.StageName != 'Closed' && opp.StageName != 'Deleted' && opp.StageName != 'Deferred Budget 25-26' && opp.StageName != 'Deferred July 2024' && opp.StageName != 'Awaiting Renewal Confirmation' && opp.School_Year__c == '25-26') {
                totalPOsGenerated += opp.Amount;
            }
        }
        System.debug('Total POs generated calculated: ' + totalPOsGenerated);
        return totalPOsGenerated;
    }
    
    public Double calculateTotalPendingSY2526(List<Opportunity> opportunities) {
        System.debug('Calculating total pending SY25-26 from ' + opportunities.size() + ' opportunities');
        Double totalPendingSY2526 = 0.0;
        for (Opportunity opp : opportunities) {
            if (opp.StageName == 'Pending' && opp.StageName != 'Closed' && opp.StageName != 'Deleted' && opp.StageName != 'Deferred Budget 25-26' && opp.StageName != 'Deferred July 2024' && opp.StageName != 'Awaiting Renewal Confirmation' && opp.School_Year__c == '25-26') {
                totalPendingSY2526 += opp.Amount;
            }
        }
        System.debug('Total pending SY25-26 calculated: ' + totalPendingSY2526);
        return totalPendingSY2526;
    }
    
    public Double calculateTotalWOsNotConverted(List<Opportunity> opportunities) {
        System.debug('Calculating total WOs not converted from ' + opportunities.size() + ' opportunities');
        Double totalWOsNotConverted = 0.0;
        for (Opportunity opp : opportunities) {
            if (opp.StageName == 'Sent Work Order/Invoice/Letter' && opp.StageName != 'Closed' && opp.StageName != 'Deleted' && opp.StageName != 'Deferred Budget 25-26' && opp.StageName != 'Deferred July 2024' && opp.StageName != 'Awaiting Renewal Confirmation' && opp.School_Year__c == '25-26') {
                totalWOsNotConverted += opp.Amount;
            }
        }
        System.debug('Total WOs not converted calculated: ' + totalWOsNotConverted);
        return totalWOsNotConverted;
    }  
    /*
    public Double calculateTotalWOsNotConverted(List<Opportunity> opportunities) {
    System.debug('Calculating total WOs not converted from ' + opportunities.size() + ' opportunities');
    Double totalWOsNotConverted = 0.0;

    for (Opportunity opp : opportunities) {
        if (opp == null) {
            System.debug('Skipping null opportunity');
            continue;
        }

        System.debug('Opportunity ID: ' + opp.Id);
        System.debug('Opportunity StageName: ' + opp.StageName);
        System.debug('Opportunity School_Year__c: ' + opp.School_Year__c);
        System.debug('Opportunity Amount: ' + opp.Amount);

        if (opp.StageName == 'Sent Work Order/Invoice/Letter' &&
            opp.StageName != 'Closed' &&
            opp.StageName != 'Deleted' &&
            opp.School_Year__c == '25-26') {
            // Use a default value of 0 if Amount is null
            Double amount = opp.Amount != null ? opp.Amount : 0.0;
            totalWOsNotConverted += amount;
        }
    }

    System.debug('Total WOs not converted calculated: ' + totalWOsNotConverted);
    return totalWOsNotConverted;
}
	*/
    public Double calculateTotalOpportunitySY2526(List<Opportunity> opportunities) {
        System.debug('Calculating total opportunity SY25-26 from ' + opportunities.size() + ' opportunities');
        Double totalOpportunitySY2526 = 0.0;
        for (Opportunity opp : opportunities) {
            if (opp.Amount != null && opp.StageName != 'Pending' && opp.StageName != 'Closed' && opp.StageName != 'Deleted' && opp.StageName != 'Deferred Budget 25-26' && opp.StageName != 'Deferred July 2024' && opp.StageName != 'Awaiting Renewal Confirmation' && opp.School_Year__c == '25-26') {
                totalOpportunitySY2526 += opp.Amount;
            }
        }
        System.debug('Total opportunity SY25-26 calculated: ' + totalOpportunitySY2526);
        return totalOpportunitySY2526;
    }
    
    public Set<String> collectProductServicesForSY2425(List<Opportunity> opportunities) {
        System.debug('Collecting product services for SY24-25 from ' + opportunities.size() + ' opportunities');
        Set<String> productServices = new Set<String>();
        for (Opportunity opp : opportunities) {
            if (opp.School_Year__c == '24-25' && String.isNotBlank(opp.Product_Service__c) && opp.StageName != 'Closed') {
                productServices.add(opp.Product_Service__c);
            }
        }
        System.debug('Found ' + productServices.size() + 'product services for SY24-25: ' + productServices);
        return productServices;
    }
    
    public Set<String> collectProductServicesForSY2526(List<Opportunity> opportunities) {
        System.debug('Collecting product services for SY25-26 from ' + opportunities.size() + ' opportunities');
        Set<String> productServices = new Set<String>();
        for (Opportunity opp : opportunities) {
            if (opp.School_Year__c == '25-26' && String.isNotBlank(opp.Product_Service__c) && opp.StageName != 'Closed' && opp.StageName != 'Pending'  && opp.StageName != 'Deleted' && opp.StageName != 'Deferred Budget 25-26' && opp.StageName != 'Deferred July 2024' && opp.StageName != 'Awaiting Renewal Confirmation') {
                productServices.add(opp.Product_Service__c);
            }
        }
        System.debug('Found ' + productServices.size() + 'product services for SY25-26: ' + productServices);
        return productServices;
    }
    
    // This is added for to calculate a product service based on product service end date for school year
    public Set<String> collectProductServicesForSY(List<Opportunity> opportunities, String defaultSchoolYear) {
    System.debug('Collecting product services for school year based on end date');
    Set<String> productServices = new Set<String>();

    for (Opportunity opp : opportunities) {
        if (String.isNotBlank(opp.Product_Service__c) && opp.StageName != 'Closed' && opp.StageName != 'Pending'  && opp.StageName != 'Deleted' && opp.StageName != 'Deferred Budget 25-26' && opp.StageName != 'Deferred July 2024' && opp.StageName != 'Awaiting Renewal Confirmation') {
            String schoolYear = opp.School_Year__c;
            if (opp.Product_Service_End_Date__c != null) {
                schoolYear = adjustSchoolYearBasedOnEndDate(opp.Product_Service_End_Date__c);
            }

            if (schoolYear == defaultSchoolYear) {
                productServices.add(opp.Product_Service__c);
            }
        }
    }

    System.debug('Found ' + productServices.size() + ' product services for school year ' + defaultSchoolYear + ': ' + productServices);
    return productServices;
}
    
    public void createPredefinedSubitems(String parentItemId, Set<String> predefinedSubitems) {
        System.debug('Creating ' + predefinedSubitems.size() + 'predefined subitems for parent ' + parentItemId);
        for (String predefinedSubitem : predefinedSubitems) {
            System.debug('Creating subitem: ' + predefinedSubitem);
            createMondaySubitem(parentItemId, predefinedSubitem, new Map<String, Object>());
        }
    }
    
    public void processOpportunities(Account acc, String mainItemId, Set<String> predefinedSubitems) {
        System.debug('Processing ' + acc.Opportunities.size() + ' opportunities for account ' + acc.Name);
        Set<String> existingSubitemNames = getExistingSubitemNames(mainItemId);
        System.debug('Found ' + existingSubitemNames.size() + ' existing subitems in Monday');
        Map<String, Double> subitemAmounts = new Map<String, Double>();
        Map<String, String> subitemStages = new Map<String, String>();
        Map<String, String> subitemSchoolYears = new Map<String, String>();
        Map<String, Date> subitemRenewalDates = new Map<String, Date>();
        Map<String, String> subitemSalespersons = new Map<String, String>();
        Map<String, Date> subitemFirstPurchaseDates = new Map<String, Date>();
        Map<String ,String> subitemDaysRemaining = new Map<String, String>();
        Map<String, Date> subitemWorkOrderSentDates = new Map<String, Date>();

        
        // Initialize amounts, stages, school years, renewal dates, salespersons, and first purchase dates for predefined subitems
        for (String subitem : predefinedSubitems) {
            subitemAmounts.put(subitem, 0.0);
            subitemStages.put(subitem, '');
            subitemSchoolYears.put(subitem, '');
            subitemRenewalDates.put(subitem, null);
            subitemSalespersons.put(subitem, '');
            subitemFirstPurchaseDates.put(subitem, null);
            subitemDaysRemaining.put(subitem, '');
            subitemWorkOrderSentDates.put(subitem, null);

        }
        
        // Group opportunities by mapped product service
        Map<String, List<Opportunity>> productServiceOpportunities = new Map<String, List<Opportunity>>();
        for (Opportunity opp : acc.Opportunities) {
            String product = opp.Product_Service__c;
            if (String.isBlank(product) || opp.StageName == 'Closed') {
                System.debug('Skipping opportunity - no product/service specified or stage is Closed');
                continue;
            }
            
            // Use the mapped product service name
            String mappedProduct = PRODUCT_SERVICE_MAPPING.containsKey(product) ? PRODUCT_SERVICE_MAPPING.get(product) : product;
            
            if (!productServiceOpportunities.containsKey(mappedProduct)) {
                productServiceOpportunities.put(mappedProduct, new List<Opportunity>());
            }
            productServiceOpportunities.get(mappedProduct).add(opp);
        }
        
        // Determine the most recent school year, latest stage, renewal date, salesperson, and first purchase date for each mapped product service
        for (String mappedProduct : productServiceOpportunities.keySet()) {
            List<Opportunity> opps = productServiceOpportunities.get(mappedProduct);
            String mostRecentSchoolYear = determineMostRecentSchoolYear(opps);
            System.debug('Most recent school year for mapped product ' + mappedProduct + ': ' + mostRecentSchoolYear);
            
            // Check if the mapped product is not in predefined subitems and not in existing subitems
            if (!predefinedSubitems.contains(mappedProduct) && !existingSubitemNames.contains(mappedProduct)) {
                System.debug('New product service found: ' + mappedProduct);
                // Create a new subitem for the new product service
                createMondaySubitem(mainItemId, mappedProduct, new Map<String, Object>());
                existingSubitemNames.add(mappedProduct); // Add to existing subitems to avoid reprocessing
            }
            
            if (predefinedSubitems.contains(mappedProduct) || existingSubitemNames.contains(mappedProduct)) {
                Double totalAmount = 0.0;
                Set<String> stages = new Set<String>();
                DateTime latestModifiedDate = null;
                Date latestRenewalDate = null;
                String latestSalesperson = '';
                Date earliestWorkOrderSentDate = null;
                String daysRemaining = '';
                
                for (Opportunity opp : opps) {
                    if (opp.School_Year__c == mostRecentSchoolYear) {
                        totalAmount += opp.Amount;
                        stages.add(opp.StageName);
                        if (latestModifiedDate == null || opp.LastModifiedDate > latestModifiedDate) {
                            latestModifiedDate = opp.LastModifiedDate;
                        }
                        // Update the latest renewal date
                        if (opp.Product_Service_End_Date__c != null && (latestRenewalDate == null || opp.Product_Service_End_Date__c > latestRenewalDate)) {
                            latestRenewalDate = opp.Product_Service_End_Date__c;
                        }
                        // Update the latest salesperson
                        if (String.isNotBlank(opp.Salesperson__c)) {
                            latestSalesperson = opp.Salesperson__c;
                        }
                        if (opp.Consultant_days_remaining__c != null) {
                            daysRemaining = String.valueOf(opp.Consultant_days_remaining__c);
                        }
                    }
                    // Calculate the earliest work order sent date across all school years
                    if (opp.Work_Order_Sent_Date__c != null && (earliestWorkOrderSentDate == null || opp.Work_Order_Sent_Date__c < earliestWorkOrderSentDate)) {
                        earliestWorkOrderSentDate = opp.Work_Order_Sent_Date__c;
                    }
                }
                
                // Adjust school year based on the renewal date
                String adjustedSchoolYear = adjustSchoolYearBasedOnRenewalDate(mostRecentSchoolYear, latestRenewalDate);
                subitemSchoolYears.put(mappedProduct, adjustedSchoolYear);
                
                // Determine the stage
                String stage = stages.size() == 1 ? stages.iterator().next() : 'Multiple Stages';
                subitemStages.put(mappedProduct, stage);
                
                // Use a conditional check to handle the case where the key might not exist
                if (subitemAmounts.containsKey(mappedProduct)) {
                    subitemAmounts.put(mappedProduct, subitemAmounts.get(mappedProduct) + totalAmount);
                } else {
                    subitemAmounts.put(mappedProduct, totalAmount);
                }
                
                subitemRenewalDates.put(mappedProduct, latestRenewalDate);
                subitemSalespersons.put(mappedProduct, latestSalesperson);
                subitemFirstPurchaseDates.put(mappedProduct, earliestWorkOrderSentDate);
                subitemDaysRemaining.put(mappedProduct, daysRemaining);
                subitemWorkOrderSentDates.put(mappedProduct, earliestWorkOrderSentDate);
                System.debug(
    'WO DEBUG | Product=' + mappedProduct +
    ' | Earliest WO Date=' + earliestWorkOrderSentDate
);

            }
        }
        
        // Update the subitems with the summed amounts, latest stages, most recent school years, renewal dates, salespersons, and first purchase dates
        for (String subitem : subitemAmounts.keySet()) {
            System.debug('Updating subitem ' + subitem + ' with amount ' + subitemAmounts.get(subitem) + ', stage ' + subitemStages.get(subitem) + ', school year ' + subitemSchoolYears.get(subitem) + ', renewal date ' + subitemRenewalDates.get(subitem) + ', salesperson ' + subitemSalespersons.get(subitem) + ', and first purchase date ' + subitemFirstPurchaseDates.get(subitem));
            System.debug(
    'WO DEBUG | Subitem=' + subitem +
    ' | Map Value=' + subitemWorkOrderSentDates.get(subitem) +
    ' | Formatted=' +
    (subitemWorkOrderSentDates.get(subitem) != null
        ? formatDate(subitemWorkOrderSentDates.get(subitem))
        : 'NULL')
);

            Map<String, Object> columnValues = new Map<String, Object>{
                'numbers' => subitemAmounts.get(subitem),
                    'stage' => subitemStages.get(subitem),
                    'school_year' => subitemSchoolYears.get(subitem),
                    'renewal_date' => subitemRenewalDates.get(subitem),
                    'salesperson' => subitemSalespersons.get(subitem),
                    'first_purchase_date' => subitemFirstPurchaseDates.get(subitem) != null ? formatDate(subitemFirstPurchaseDates.get(subitem)) : null,
                        'days_remaining' => subitemDaysRemaining.get(subitem),
                        'work_order_sent_date' =>
        subitemWorkOrderSentDates.get(subitem) != null
            ? formatDate(subitemWorkOrderSentDates.get(subitem))
            : null
                        };
                            updateMondaySubitem(mainItemId, subitem, columnValues);
        }
    }
    
    private String adjustSchoolYearBasedOnRenewalDate(String schoolYear, Date renewalDate) {
        if (renewalDate == null) {
            return schoolYear;
        }
        
        // Extract the year from the renewal date
        Integer renewalYear = renewalDate.year();
        // Format the school year as "YY-YY"
        String startYear = String.valueOf(renewalYear - 1).substring(2);
        String endYear = String.valueOf(renewalYear).substring(2);
        
        // Set the school year based on the renewal year
        return startYear + '-' + endYear;
    }
    
    private String determineMostRecentSchoolYear(List<Opportunity> opportunities) {
        System.debug('Determining most recent school year from ' + opportunities.size() + ' opportunities');
        Set<String> schoolYears = new Set<String>();
        for (Opportunity opp : opportunities) {
            if (String.isNotBlank(opp.School_Year__c)) {
                schoolYears.add(opp.School_Year__c);
            }
        }
        
        if (schoolYears.isEmpty()) {
            System.debug('No school years found');
            return null;
        }
        
        List<String> sortedSchoolYears = new List<String>(schoolYears);
        sortedSchoolYears.sort();
        String mostRecentSchoolYear = sortedSchoolYears.get(sortedSchoolYears.size() - 1);
        System.debug('Most recent school year: ' + mostRecentSchoolYear);
        return mostRecentSchoolYear;
    }
    
    private void createNewSubitems(String parentItemId, Set<String> newProductServices) {
        System.debug('Creating new subitems for parent ' + parentItemId + ': ' + newProductServices);
        for (String newProd : newProductServices) {
            System.debug('Creating subitem for: ' + newProd);
            createMondaySubitem(parentItemId, newProd, new Map<String, Object>());
        }
    }
    
    public Set<String> getExistingDBNsFromMonday() {
        System.debug('Getting existing DBNs from Monday');
        String query = 'query { boards (ids: ' + BOARD_ID + ') { items_page(limit: 500) { items { name } } } }';
        HttpResponse res = sendMondayRequest(query);
        System.debug('Monday API response status: ' + res.getStatusCode());
        
        Set<String> dbns = new Set<String>();
        
        if (res.getStatusCode() == 200) {
            try {
                Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (json.containsKey('data')) {
                    Map<String, Object> data = (Map<String, Object>) json.get('data');
                    if (data.containsKey('boards')) {
                        List<Object> boards = (List<Object>) data.get('boards');
                        if (!boards.isEmpty()) {
                            Map<String, Object> board = (Map<String, Object>) boards[0];
                            if (board.containsKey('items_page')) {
                                Map<String, Object> itemsPage = (Map<String, Object>) board.get('items_page');
                                if (itemsPage.containsKey('items')) {
                                    List<Object> items = (List<Object>) itemsPage.get('items');
                                    System.debug('Found ' + items.size() + ' items in Monday');
                                    for (Object itemObj : items) {
                                        Map<String, Object> item = (Map<String, Object>) itemObj;
                                        if (item.containsKey('name')) {
                                            dbns.add((String) item.get('name'));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error parsing JSON response: ' + e.getMessage());
            }
        } else {
            System.debug('Error getting DBNs from Monday: ' + res.getStatus() + ' - ' + res.getBody());
        }
        
        return dbns;
    }
    
    public String getMondayItemIdByDBN(String dbn) {
        System.debug('Getting Monday item ID for DBN: ' + dbn);
        String query = 'query { boards (ids: ' + BOARD_ID + ') { items_page(limit: 500) { items { id name } } } }';
        HttpResponse res = sendMondayRequest(query);
        System.debug('Monday API response status: ' + res.getStatusCode());
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (json.containsKey('data')) {
                Map<String, Object> data = (Map<String, Object>) json.get('data');
                List<Object> boards = (List<Object>) data.get('boards');
                if (!boards.isEmpty()) {
                    Map<String, Object> board = (Map<String, Object>) boards[0];
                    Map<String, Object> itemsPage = (Map<String, Object>) board.get('items_page');
                    List<Object> items = (List<Object>) itemsPage.get('items');
                    System.debug('Searching ' + items.size() + 'items for DBN: ' + dbn);
                    for (Object itemObj : items) {
                        Map<String, Object> item = (Map<String, Object>) itemObj;
                        if ((String) item.get('name') == dbn) {
                            System.debug('Found matching item with ID: ' + item.get('id'));
                            return String.valueOf(item.get('id'));
                        }
                    }
                }
            }
        } else {
            System.debug('Error getting item ID from Monday: ' + res.getStatus() + ' - ' + res.getBody());
        }
        
        System.debug('No item found for DBN: ' + dbn);
        return null;
    }
    
    public Set<String> getExistingSubitemNames(String parentItemId) {
        System.debug('Getting existing subitem names for parent: ' + parentItemId);
        String query = 'query { items (ids: ' + parentItemId + ') { subitems { name } } }';
        HttpResponse res = sendMondayRequest(query);
        System.debug('Monday API response status: ' + res.getStatusCode());
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (json.containsKey('data')) {
                Map<String, Object> data = (Map<String, Object>) json.get('data');
                List<Object> items = (List<Object>) data.get('items');
                if (!items.isEmpty()) {
                    Map<String, Object> item = (Map<String, Object>) items[0];
                    List<Object> subitems = (List<Object>) item.get('subitems');
                    System.debug('Found ' + subitems.size() + ' subitems');
                    Set<String> subitemNames = new Set<String>();
                    for (Object subitemObj : subitems) {
                        Map<String, Object> subitem = (Map<String, Object>) subitemObj;
                        String name = (String) subitem.get('name');
                        if (String.isNotBlank(name)) {
                            subitemNames.add(name.trim());
                        }
                    }
                    return subitemNames;
                }
            }
        } else {
            System.debug('Error getting subitems from Monday: ' + res.getStatus() + ' - ' + res.getBody());
        }
        
        return new Set<String>();
    }
    
    private String createMondayItem(String itemName, Map<String, Object> columnValues) {
        System.debug('Creating Monday item: ' + itemName);
        
        // Format the link column if it exists
        if (columnValues.containsKey(OPPS_SHEET_COLUMN_ID) && columnValues.get(OPPS_SHEET_COLUMN_ID) != null) {
            String url = (String) columnValues.get(OPPS_SHEET_COLUMN_ID);
            columnValues.put(OPPS_SHEET_COLUMN_ID, formatLinkColumnValue(url, 'View Dashboard'));
        }
        
        // Remove null values to avoid API errors
        Map<String, Object> filteredColumnValues = new Map<String, Object>();
        for (String key : columnValues.keySet()) {
            if (columnValues.get(key) != null) {
                filteredColumnValues.put(key, columnValues.get(key));
            }
        }
        
        System.debug('Column values: ' + filteredColumnValues);
        String colsJson = JSON.serialize(filteredColumnValues).replace('"', '\\"');
        String mutation = 'mutation { create_item (board_id: ' + BOARD_ID + ', item_name: "' + itemName + '", column_values: "' + colsJson + '") { id } }';
        System.debug('Mutation: ' + mutation);
        HttpResponse res = sendMondayRequest(mutation);
        System.debug('Monday API response status: ' + res.getStatusCode());
        System.debug('Response body: ' + res.getBody());
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (json.containsKey('data')) {
                Map<String, Object> data = (Map<String, Object>) json.get('data');
                Map<String, Object> createItem = (Map<String, Object>) data.get('create_item');
                if (createItem != null) {
                    String itemId = String.valueOf(createItem.get('id'));
                    System.debug('Created item with ID: ' + itemId);
                    return itemId;
                }
            }
        }
        
        System.debug('Failed to create item');
        return null;
    }
    
    private void createMondaySubitem(String parentItemId, String subitemName, Map<String, Object> columnValues) {
        System.debug('Creating subitem for parent ' + parentItemId + ': ' + subitemName);
        System.debug('Column values: ' + columnValues);
        String colsJson = JSON.serialize(columnValues).replace('"', '\\"');
        String mutation = 'mutation { create_subitem (parent_item_id: ' + parentItemId + ', item_name: "' + subitemName + '", column_values: "' + colsJson + '") { id } }';
        System.debug('Mutation: ' + mutation);
        HttpResponse res = sendMondayRequest(mutation);
        System.debug('Monday API response status: ' + res.getStatusCode());
        System.debug('Response body: ' + res.getBody());
    }
    // Add a small change to the updateMondayItem method to include DBN column
    /*
    private void updateMondayItem(String itemId, String principalEmail, Date earliestWorkOrderSentDate, Double totalAmount, Double totalPOsGenerated, Double totalPendingSY2526, Double totalWOsNotConverted, Double totalOpportunitySY2526, Set<String> productServicesSY2425, Set<String> productServicesSY2526, String principalName, String oppsSheet, String district, String address , Double lat , Double lng,String state) {
        System.debug('Updating Monday item: ' + itemId);
        Map<String, Object> columnValues = new Map<String, Object>{
            PRINCIPAL_EMAIL_COLUMN_ID => principalEmail,
                PARTNER_COLUMN_ID => earliestWorkOrderSentDate != null ? formatDate(earliestWorkOrderSentDate) : null,
                    SPENT_ALL_TIME_COLUMN_ID => totalAmount,
                    TOTAL_POS_GENERATED_COLUMN_ID => totalPOsGenerated,
                    PENDING_SY_25_26_COLUMN_ID => totalPendingSY2526,
                    WOS_NOT_CONVERTED_COLUMN_ID => totalWOsNotConverted,
                    OPPORTUNITY_SY_25_26_COLUMN_ID => totalOpportunitySY2526,
                    SERVICES_SY_24_25_COLUMN_ID => String.join(new List<String>(productServicesSY2425), ', '),
                    SERVICES_SY_25_26_COLUMN_ID => String.join(new List<String>(productServicesSY2526), ', '),
                    PRINCIPAL_NAME_COLUMN_ID => principalName,
                    OPPS_SHEET_COLUMN_ID => formatLinkColumnValue(oppsSheet, 'View Dashboard'),
                    OPPS_DISTRICT_COLUMN_ID => district ,
                    ADDRESS_COLUMN_ID => new Map<String, Object>{
                        'address' => address,
                            'lat' => lat,
                            'lng' => lng
                            },
                    STATE_COLUMN_ID => state
        };
            
            // Remove null values to avoid API errors
            Map<String, Object> filteredColumnValues = new Map<String, Object>();
        for (String key : columnValues.keySet()) {
            if (columnValues.get(key) != null) {
                filteredColumnValues.put(key, columnValues.get(key));
            }
        }
        
        System.debug('Column values for update: ' + filteredColumnValues);
        String colsJson = JSON.serialize(filteredColumnValues).replace('"', '\\"');
        String mutation = 'mutation { change_multiple_column_values(item_id: ' + itemId + ', board_id: ' + BOARD_ID + ', column_values: "' + colsJson + '") { id } }';
        System.debug('Mutation: ' + mutation);
        HttpResponse res = sendMondayRequest(mutation);
        System.debug('Monday API response status: ' + res.getStatusCode());
        System.debug('Response body: ' + res.getBody());
    }
    */
    
    private void updateMondayItem(String itemId, String principalEmail,String dbn, Date earliestWorkOrderSentDate, Double totalAmount, Double totalPOsGenerated, Double totalPendingSY2526, Double totalWOsNotConverted, Double totalOpportunitySY2526, Set<String> productServicesSY2425, Set<String> productServicesSY2526, String principalName, String oppsSheet, String district, String address, Double lat, Double lng, String state) {
    System.debug('Updating Monday item: ' + itemId);
    Map<String, Object> columnValues = new Map<String, Object>{
        PRINCIPAL_EMAIL_COLUMN_ID => principalEmail,
            DBN_COLUMN_ID => dbn,
        PARTNER_COLUMN_ID => earliestWorkOrderSentDate != null ? formatDate(earliestWorkOrderSentDate) : null,
        SPENT_ALL_TIME_COLUMN_ID => totalAmount,
        TOTAL_POS_GENERATED_COLUMN_ID => totalPOsGenerated,
        PENDING_SY_25_26_COLUMN_ID => totalPendingSY2526,
        WOS_NOT_CONVERTED_COLUMN_ID => totalWOsNotConverted,
        OPPORTUNITY_SY_25_26_COLUMN_ID => totalOpportunitySY2526,
        SERVICES_SY_24_25_COLUMN_ID => String.join(new List<String>(productServicesSY2425), ', '),
        SERVICES_SY_25_26_COLUMN_ID => String.join(new List<String>(productServicesSY2526), ', '),
        PRINCIPAL_NAME_COLUMN_ID => principalName,
        OPPS_SHEET_COLUMN_ID => formatLinkColumnValue(oppsSheet, 'View Dashboard'),
        OPPS_DISTRICT_COLUMN_ID => district,
        ADDRESS_COLUMN_ID => new Map<String, Object>{
            'address' => address,
            'lat' => lat,
            'lng' => lng
        },
        STATE_COLUMN_ID => state
    };

    // Remove null values to avoid API errors
    Map<String, Object> filteredColumnValues = new Map<String, Object>();
    for (String key : columnValues.keySet()) {
        if (columnValues.get(key) != null) {
            filteredColumnValues.put(key, columnValues.get(key));
        }
    }

    System.debug('Column values for update: ' + filteredColumnValues);
    String colsJson = JSON.serialize(filteredColumnValues).replace('"', '\\"');
    String mutation = 'mutation { change_multiple_column_values(item_id: ' + itemId + ', board_id: ' + BOARD_ID + ', column_values: "' + colsJson + '") { id } }';
    System.debug('Mutation: ' + mutation);
    HttpResponse res = sendMondayRequest(mutation);
    System.debug('Monday API response status: ' + res.getStatusCode());
    System.debug('Response body: ' + res.getBody());
}

    private void updateMondaySubitem(String parentItemId, String subitemName, Map<String, Object> columnValues) {
        System.debug('Updating subitem ' + subitemName + ' for parent ' + parentItemId);
        System.debug('Column values: ' + columnValues);
        
        String subitemId = getMondaySubitemIdByName(parentItemId, subitemName);
        System.debug('Subitem ID: ' + subitemId);
        if (String.isBlank(subitemId)) {
            System.debug('No subitem ID found, skipping update');
            return;
        }
        
        String subitemBoardId = getSubitemBoardId();
        System.debug('Subitem board ID: ' + subitemBoardId);
        if (String.isBlank(subitemBoardId)) {
            System.debug('No subitem board ID found, skipping update');
            return;
        }
        
        // Prepare only valid columns that exist in the input
        Map<String, Object> columnValuesMap = new Map<String, Object>();
        if (columnValues.containsKey('numbers') && columnValues.get('numbers') != null) {
            columnValuesMap.put(SUBITEM_AMOUNT_COLUMN_ID, columnValues.get('numbers'));
        }
        if (columnValues.containsKey('stage') && columnValues.get('stage') != null) {
            columnValuesMap.put(SUBITEM_STAGE_COLUMN_ID, columnValues.get('stage'));
        }
        if (columnValues.containsKey('school_year') && columnValues.get('school_year') != null) {
            columnValuesMap.put(SUBITEM_YEAR_COLUMN_ID, columnValues.get('school_year')); // Include school year column
        }
        if (columnValues.containsKey('renewal_date') && columnValues.get('renewal_date') != null) {
            columnValuesMap.put(SUBITEM_DATE_COLUMN_ID, formatDate(columnValues.get('renewal_date'))); // Include renewal date column
        }
        if (columnValues.containsKey('salesperson') && columnValues.get('salesperson') != null) {
            columnValuesMap.put(SUBITEM_SALESPERSON_COLUMN_ID, columnValues.get('salesperson')); // Include salesperson column
        }
        if (columnValues.containsKey('partner_pocs') && columnValues.get('partner_pocs') != null) {
            columnValuesMap.put(SUBITEM_PARTNER_COLUMN_ID, columnValues.get('partner_pocs')); // Include Partner POCs column
        }
        if (columnValues.containsKey('first_purchase_date') && columnValues.get('first_purchase_date') != null) {
            columnValuesMap.put(SUBITEM_FIRST_PURCHASE_COLUMN_ID, columnValues.get('first_purchase_date')); // Include Partner POCs column
        }
        if (columnValues.containsKey('days_remaining') && columnValues.get('days_remaining') != null) {
            columnValuesMap.put(SUBITEM_DAYS_REMAINING_COLUMN_ID, columnValues.get('days_remaining')); // Include Partner POCs column
        }
        if (columnValues.containsKey('work_order_sent_date') &&
    columnValues.get('work_order_sent_date') != null) {
    columnValuesMap.put(
        SUBITEM_DATE_WORK_ORDER_SENT,
        columnValues.get('work_order_sent_date')
    );
        System.debug(
    'WO DEBUG | Monday Payload | Subitem=' + subitemName +
    ' | ColumnId=' + SUBITEM_DATE_WORK_ORDER_SENT +
    ' | Value=' + columnValues.get('work_order_sent_date')
);

}

        if (columnValuesMap.isEmpty()) {
            System.debug('No valid columns to update for subitem: ' + subitemName);
            return;
        }
        
        String colsJson = JSON.serialize(columnValuesMap).replace('"', '\\"');
        String mutation = 'mutation { change_multiple_column_values(item_id: ' + subitemId + ', board_id: ' + subitemBoardId + ', column_values: "' + colsJson + '") { id } }';
        System.debug('Mutation: ' + mutation);
        HttpResponse res = sendMondayRequest(mutation);
        System.debug('Monday API response status: ' + res.getStatusCode());
        System.debug('Response body: ' + res.getBody());
    }
    
    public String getSubitemBoardId() {
        System.debug('Getting subitem board ID');
        String query = 'query { boards(ids: ' + BOARD_ID + ') { columns(types: [subtasks]) { settings_str } } }';
        HttpResponse res = sendMondayRequest(query);
        System.debug('Monday API response status: ' + res.getStatusCode());
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (json.containsKey('data')) {
                Map<String, Object> data = (Map<String, Object>) json.get('data');
                List<Object> boards = (List<Object>) data.get('boards');
                if (!boards.isEmpty()) {
                    Map<String, Object> board = (Map<String, Object>) boards[0];
                    List<Object> columns = (List<Object>) board.get('columns');
                    System.debug('Checking ' + columns.size() + 'columns for subtasks');
                    for (Object columnObj : columns) {
                        Map<String, Object> column = (Map<String, Object>) columnObj;
                        String settingsStr = (String) column.get('settings_str');
                        if (String.isNotBlank(settingsStr)) {
                            try {
                                Map<String, Object> settings = (Map<String, Object>) System.JSON.deserializeUntyped(settingsStr);
                                System.debug('Parsed settings: ' + settings);
                                if (settings.containsKey('boardIds')) {
                                    List<Object> boardIds = (List<Object>) settings.get('boardIds');
                                    if (!boardIds.isEmpty()) {
                                        String boardId = String.valueOf(boardIds[0]);
                                        System.debug('Found subitem board ID: ' + boardId);
                                        return boardId;
                                    }
                                }
                            } catch (Exception e) {
                                System.debug('Error parsing settings_str: ' + e.getMessage());
                            }
                        }
                    }
                }
            }
        } else {
            System.debug('Error getting subitem board ID: ' + res.getStatus() + ' - ' + res.getBody());
        }
        
        System.debug('No subitem board ID found');
        return null;
    }
    
    public String getMondaySubitemIdByName(String parentItemId, String subitemName) {
        System.debug('Getting subitem ID for ' + subitemName + ' under parent ' + parentItemId);
        String query = 'query { items (ids: ' + parentItemId + ') { subitems { id name } } }';
        HttpResponse res = sendMondayRequest(query);
        System.debug('Monday API response status: ' + res.getStatusCode());
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (json.containsKey('data')) {
                Map<String, Object> data = (Map<String, Object>) json.get('data');
                List<Object> items = (List<Object>) data.get('items');
                if (!items.isEmpty()) {
                    Map<String, Object> item = (Map<String, Object>) items[0];
                    List<Object> subitems = (List<Object>) item.get('subitems');
                    System.debug('Searching ' + subitems.size() + ' subitems');
                    for (Object subitemObj : subitems) {
                        Map<String, Object> subitem = (Map<String, Object>) subitemObj;
                        if ((String) subitem.get('name') == subitemName) {
                            System.debug('Found matching subitem with ID: ' + subitem.get('id'));
                            return String.valueOf(subitem.get('id'));
                        }
                    }
                }
            }
        } else {
            System.debug('Error getting subitems: ' + res.getStatus() + ' - ' + res.getBody());
        }
        
        System.debug('No matching subitem found');
        return null;
    }
    
    public String formatDate(Object dateValue) {
        if (dateValue == null) {
            System.debug('Date value is null');
            return null;
        }
        try {
            Date d = (Date) dateValue;
            String formatted = DateTime.newInstance(d.year(), d.month(), d.day()).format('yyyy-MM-dd');
            System.debug('Formatted date: ' + formatted + ' from ' + dateValue);
            return formatted;
        } catch (Exception e) {
            System.debug('Error formatting date: ' + e.getMessage());
            return null;
        }
    }
    
    private HttpResponse sendMondayRequest(String graphqlQuery) {
        System.debug('Sending Monday API request');
        System.debug('GraphQL query: ' + graphqlQuery);
        String token = getMondayAPIToken();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, Object>{ 'query' => graphqlQuery }));
        req.setTimeout(120000);
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Monday API response received');
            return res;
        } catch (Exception e) {
            System.debug('Error sending Monday API request: ' + e.getMessage());
            throw new MondayIntegrationException('Monday API request failed: ' + e.getMessage());
        }
    }  
    
    public static String getMondayAPIToken() {
        if (Test.isRunningTest()) {
            System.debug('Running test, returning test token');
            return 'test-api-token-123';
        }
        try {
            StaticResource tokenResource = [SELECT Body FROM StaticResource WHERE Name = 'MondayAPIToken' LIMIT 1];
            System.debug('Monday API token loaded from static resource');
            return tokenResource.Body.toString().trim();
        } catch (Exception e) {
            System.debug('Error loading Monday API token: ' + e.getMessage());
            throw new MondayIntegrationException('Error loading Monday API token: ' + e.getMessage());
        }
    }
    
    public class MondayIntegrationException extends Exception {}
}