public class OpportunityChangeDetector {

    public static Boolean hasRelevantChanges(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        for (Opportunity n : newList) {
            Opportunity o = oldMap.get(n.Id);

            if (changed(n.Name, o.Name)) return true;
            if (changed(n.Product_Service__c, o.Product_Service__c)) return true;
            if (changed(n.Amount, o.Amount)) return true;
            if (changed(n.CloseDate, o.CloseDate)) return true;
            if (changed(n.Work_Order_Sent_Date__c, o.Work_Order_Sent_Date__c)) return true;
            if (changed(n.StageName, o.StageName)) return true;
            if (changed(n.Fully_Paid_Date__c, o.Fully_Paid_Date__c)) return true;
            if (changed(n.School_Year__c, o.School_Year__c)) return true;
            if (changed(n.Fully_Invoiced_Date__c, o.Fully_Invoiced_Date__c)) return true;
            if (changed(n.Partial_Invoice_Date__c, o.Partial_Invoice_Date__c)) return true;
            if (changed(n.Partially_Invoiced_Date__c, o.Partially_Invoiced_Date__c)) return true;
            if (changed(n.Latest_Invoice_Date_Issued__c, o.Latest_Invoice_Date_Issued__c)) return true;
            if (changed(n.Partially_paid_Date__c, o.Partially_paid_Date__c)) return true;
            if (changed(n.Account_Full_Name__c, o.Account_Full_Name__c)) return true;
            if (changed(n.Pre_Paid__c, o.Pre_Paid__c)) return true;
            if (changed(n.Purchase_Order_Date__c, o.Purchase_Order_Date__c)) return true;
            if (changed(n.TOTAL_INVOICED_TO_DATE_NEW__c, o.TOTAL_INVOICED_TO_DATE_NEW__c)) return true;
            if (changed(n.Remaining_Amount__c, o.Remaining_Amount__c)) return true;
            if (changed(n.Salesperson__c, o.Salesperson__c)) return true;

        }
        return false;
    }

    private static Boolean changed(Object a, Object b) {
        if (a == null && b == null) return false;
        if (a == null || b == null) return true;
        return String.valueOf(a) != String.valueOf(b);
    }
}