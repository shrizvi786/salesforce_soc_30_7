public class CommissionPaymentHandler {
    public static void createCommissionPayments(List<Accounting_Accrual_Standards__c> newAccruals, Map<Id, Accounting_Accrual_Standards__c> oldMap) {
        List<Accounting_Accrual_Standards__c> relevantAccruals = new List<Accounting_Accrual_Standards__c>();

        if (oldMap != null) {
            for (Accounting_Accrual_Standards__c newAcc : newAccruals) {
                Accounting_Accrual_Standards__c oldAcc = oldMap.get(newAcc.Id);
                if (
                    newAcc.Accrual_Amount__c != oldAcc.Accrual_Amount__c ||
                    newAcc.Salesperson_Contact__c != oldAcc.Salesperson_Contact__c ||
                    newAcc.Start_Date__c != oldAcc.Start_Date__c
                ) {
                    relevantAccruals.add(newAcc);
                }
            }
        } else {
            relevantAccruals.addAll(newAccruals);
        }

        if (relevantAccruals.isEmpty()) return;

        Set<Id> accrualIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Accounting_Accrual_Standards__c acc : relevantAccruals) {
            accrualIds.add(acc.Id);
            contactIds.add(acc.Salesperson_Contact__c);
        }

        Map<Id, List<Commission_Payment__c>> existingCommissionsMap = new Map<Id, List<Commission_Payment__c>>();
        for (Commission_Payment__c cp : [
            SELECT Id, Accounting_Accrual_Standards__c
            FROM Commission_Payment__c
            WHERE Accounting_Accrual_Standards__c IN :accrualIds
        ]) {
            if (!existingCommissionsMap.containsKey(cp.Accounting_Accrual_Standards__c)) {
                existingCommissionsMap.put(cp.Accounting_Accrual_Standards__c, new List<Commission_Payment__c>());
            }
            existingCommissionsMap.get(cp.Accounting_Accrual_Standards__c).add(cp);
        }

        List<Accounting_Accrual_Standards__c> allRelatedAccruals = [
            SELECT Id, Start_Date__c, Salesperson_Contact__c, Accrual_Amount__c
            FROM Accounting_Accrual_Standards__c
            WHERE Salesperson_Contact__c IN :contactIds
        ];

        List<Commission_Payment__c> paymentsToInsert = new List<Commission_Payment__c>();

        for (Accounting_Accrual_Standards__c newAcc : relevantAccruals) {
            if (newAcc.Salesperson_Contact__c == null || newAcc.Start_Date__c == null) continue;
            if (existingCommissionsMap.containsKey(newAcc.Id)) continue;

            Decimal totalAccrual = 0;
            for (Accounting_Accrual_Standards__c acc : allRelatedAccruals) {
                if (acc.Salesperson_Contact__c == newAcc.Salesperson_Contact__c &&
                    acc.Start_Date__c <= newAcc.Start_Date__c) {
                    totalAccrual += acc.Accrual_Amount__c != null ? acc.Accrual_Amount__c : 0;
                }
            }

            Decimal commissionRate = getCommissionRate(totalAccrual);
            Decimal commissionAmount = (newAcc.Accrual_Amount__c != null)
                ? (newAcc.Accrual_Amount__c * commissionRate) / 100
                : 0;

            Date eom = Date.newInstance(newAcc.Start_Date__c.year(), newAcc.Start_Date__c.month(), 1)
                .addMonths(1).addDays(-1);

            paymentsToInsert.add(new Commission_Payment__c(
                Accounting_Accrual_Standards__c = newAcc.Id,
                Salesperson_Contact__c = newAcc.Salesperson_Contact__c,
                Commision__c = String.valueOf(commissionRate),
                Commission_Amount__c = commissionAmount,
                Notes__c = 'Created using automation',
                EOM__c = eom
            ));
        }

        if (!paymentsToInsert.isEmpty()) {
            insert paymentsToInsert;
        }
    }

    private static Decimal getCommissionRate(Decimal totalAccrual) {
        if (totalAccrual <= 249999.99) return 4;
        else if (totalAccrual <= 499999.99) return 4.5;
        else if (totalAccrual <= 749999.99) return 5;
        else if (totalAccrual <= 999999.99) return 5.5;
        else if (totalAccrual <= 1249999.99) return 6;
        else if (totalAccrual <= 1499999.99) return 6.5;
        else if (totalAccrual <= 1749999.99) return 7;
        else return 7.5;
    }
}


/*
 * public class CommissionPaymentHandler {
    public static void createCommissionPayments(List<Accounting_Accrual_Standards__c> newAccruals, Map<Id, Accounting_Accrual_Standards__c> oldMap) {
        List<Accounting_Accrual_Standards__c> relevantAccruals = new List<Accounting_Accrual_Standards__c>();

        // Handle updates - only process changed records
        if (oldMap != null) {
            for (Accounting_Accrual_Standards__c newAcc : newAccruals) {
                Accounting_Accrual_Standards__c oldAcc = oldMap.get(newAcc.Id);
                if (
                    newAcc.Accrual_Amount__c != oldAcc.Accrual_Amount__c ||
                    newAcc.Salesperson_Contact__c != oldAcc.Salesperson_Contact__c ||
                    newAcc.Start_Date__c != oldAcc.Start_Date__c
                ) {
                    relevantAccruals.add(newAcc);
                }
            }
        } else {
            relevantAccruals.addAll(newAccruals);
        }

        if (relevantAccruals.isEmpty()) return;

        // Step 1: Check existing commission records
        Set<Id> accrualIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Accounting_Accrual_Standards__c acc : relevantAccruals) {
            if (acc.Id != null) accrualIds.add(acc.Id);
            if (acc.Salesperson_Contact__c != null) contactIds.add(acc.Salesperson_Contact__c);
        }

        Map<Id, List<Commission_Payment__c>> existingCommissionsMap = new Map<Id, List<Commission_Payment__c>>();
        for (Commission_Payment__c cp : [
            SELECT Id, Accounting_Accrual_Standards__c
            FROM Commission_Payment__c
            WHERE Accounting_Accrual_Standards__c IN :accrualIds
        ]) {
            if (!existingCommissionsMap.containsKey(cp.Accounting_Accrual_Standards__c)) {
                existingCommissionsMap.put(cp.Accounting_Accrual_Standards__c, new List<Commission_Payment__c>());
            }
            existingCommissionsMap.get(cp.Accounting_Accrual_Standards__c).add(cp);
        }

        // Step 2: Query all related accruals for total calculation
        List<Accounting_Accrual_Standards__c> allRelatedAccruals = [
            SELECT Id, Start_Date__c, Salesperson_Contact__c, Accrual_Amount__c
            FROM Accounting_Accrual_Standards__c
            WHERE Salesperson_Contact__c IN :contactIds
        ];

        List<Commission_Payment__c> paymentsToInsert = new List<Commission_Payment__c>();

        for (Accounting_Accrual_Standards__c newAcc : relevantAccruals) {
            if (newAcc.Salesperson_Contact__c == null || newAcc.Start_Date__c == null) continue;

            // Skip if there's already one or more commission records for this accrual
            if (existingCommissionsMap.containsKey(newAcc.Id) && !existingCommissionsMap.get(newAcc.Id).isEmpty()) {
                continue;
            }

            // Step 3: Calculate total accruals up to the current start date
            Decimal totalAccrual = 0;
            for (Accounting_Accrual_Standards__c acc : allRelatedAccruals) {
                if (
                    acc.Salesperson_Contact__c == newAcc.Salesperson_Contact__c &&
                    acc.Start_Date__c <= newAcc.Start_Date__c
                ) {
                    totalAccrual += acc.Accrual_Amount__c != null ? acc.Accrual_Amount__c : 0;
                }
            }

            Decimal commissionRate = getCommissionRate(totalAccrual);
            Decimal commissionAmount = (newAcc.Accrual_Amount__c != null)
                ? (newAcc.Accrual_Amount__c * commissionRate) / 100
                : 0;

            Date eom = Date.newInstance(newAcc.Start_Date__c.year(), newAcc.Start_Date__c.month(), 1)
                         .addMonths(1).addDays(-1);

            Commission_Payment__c payment = new Commission_Payment__c(
                Accounting_Accrual_Standards__c = newAcc.Id,
                Salesperson_Contact__c = newAcc.Salesperson_Contact__c,
                Commision__c = String.valueOf(commissionRate),
                Commission_Amount__c = commissionAmount,
                Notes__c = 'Created using automation',
                EOM__c = eom
            );

            paymentsToInsert.add(payment);
        }

        if (!paymentsToInsert.isEmpty()) {
            insert paymentsToInsert;
        }
    }

    private static Decimal getCommissionRate(Decimal totalAccrual) {
        if (totalAccrual <= 249999.99) return 4;
        else if (totalAccrual <= 499999.99) return 4.5;
        else if (totalAccrual <= 749999.99) return 5;
        else if (totalAccrual <= 999999.99) return 5.5;
        else if (totalAccrual <= 1249999.99) return 6;
        else if (totalAccrual <= 1499999.99) return 6.5;
        else if (totalAccrual <= 1749999.99) return 7;
        else return 7.5;
    }
}
*/
/*
public class CommissionPaymentHandler {
    public static void createCommissionPayments(List<Accounting_Accrual_Standards__c> newAccruals, Map<Id, Accounting_Accrual_Standards__c> oldMap) {
        List<Accounting_Accrual_Standards__c> relevantAccruals = new List<Accounting_Accrual_Standards__c>();

        // If update, check if relevant fields changed
        if (oldMap != null) {
            for (Accounting_Accrual_Standards__c newAcc : newAccruals) {
                Accounting_Accrual_Standards__c oldAcc = oldMap.get(newAcc.Id);
                if (
                    newAcc.Accrual_Amount__c != oldAcc.Accrual_Amount__c ||
                    newAcc.Salesperson_Contact__c != oldAcc.Salesperson_Contact__c ||
                    newAcc.Start_Date__c != oldAcc.Start_Date__c
                ) {
                    relevantAccruals.add(newAcc);
                }
            }
        } else {
            relevantAccruals.addAll(newAccruals);
        }

        if (relevantAccruals.isEmpty()) return;

        Set<Id> contactIds = new Set<Id>();
        for (Accounting_Accrual_Standards__c acc : relevantAccruals) {
            if (acc.Salesperson_Contact__c != null) {
                contactIds.add(acc.Salesperson_Contact__c);
            }
        }

        // Query all accruals for the relevant Salesperson_Contact__c
        List<Accounting_Accrual_Standards__c> allRelatedAccruals = [
            SELECT Id, Start_Date__c, Salesperson_Contact__c, Accrual_Amount__c
            FROM Accounting_Accrual_Standards__c
            WHERE Salesperson_Contact__c IN :contactIds
        ];

        List<Commission_Payment__c> paymentsToInsert = new List<Commission_Payment__c>();

        for (Accounting_Accrual_Standards__c newAcc : relevantAccruals) {
            if (newAcc.Salesperson_Contact__c == null || newAcc.Start_Date__c == null) continue;

            // Calculate total accrual up to current Start_Date__c
            Decimal totalAccrual = 0;
            for (Accounting_Accrual_Standards__c acc : allRelatedAccruals) {
                if (
                    acc.Salesperson_Contact__c == newAcc.Salesperson_Contact__c &&
                    acc.Start_Date__c <= newAcc.Start_Date__c
                ) {
                    totalAccrual += acc.Accrual_Amount__c != null ? acc.Accrual_Amount__c : 0;
                }
            }

            Decimal commissionRate = getCommissionRate(totalAccrual);
            Decimal commissionAmount = (newAcc.Accrual_Amount__c != null)
                ? (newAcc.Accrual_Amount__c * commissionRate) / 100
                : 0;

            // Calculate EOM
            Date eom = Date.newInstance(newAcc.Start_Date__c.year(), newAcc.Start_Date__c.month(), 1)
                         .addMonths(1).addDays(-1);

            Commission_Payment__c payment = new Commission_Payment__c(
                Accounting_Accrual_Standards__c = newAcc.Id,
                Salesperson_Contact__c = newAcc.Salesperson_Contact__c,
                Commision__c = String.valueOf(commissionRate),
                Commission_Amount__c = commissionAmount,
                Notes__c = 'Created using automation',
                EOM__c = eom
            );

            paymentsToInsert.add(payment);
        }

        if (!paymentsToInsert.isEmpty()) {
            insert paymentsToInsert;
        }
    }

    private static Decimal getCommissionRate(Decimal totalAccrual) {
        if (totalAccrual <= 249999.99) return 4;
        else if (totalAccrual <= 499999.99) return 4.5;
        else if (totalAccrual <= 749999.99) return 5;
        else if (totalAccrual <= 999999.99) return 5.5;
        else if (totalAccrual <= 1249999.99) return 6;
        else if (totalAccrual <= 1499999.99) return 6.5;
        else if (totalAccrual <= 1749999.99) return 7;
        else return 7.5;
    }
}


*/