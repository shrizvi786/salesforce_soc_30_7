trigger ProductServiceUpdateTrigger on Product_Service_Update__c (after insert, after update) {
    Set<String> dbns = new Set<String>();
    Set<String> services = new Set<String>();

    // Collect DBNs and services from the updated or inserted records
    for (Product_Service_Update__c psUpdate : Trigger.new) {
        if (psUpdate.DBN__c != null && psUpdate.Product_Service__c != null) {
            dbns.add(psUpdate.DBN__c);
            services.add(psUpdate.Product_Service__c);
        }
    }

    // Enqueue a job to update Monday.com board columns
    if (!dbns.isEmpty() && !services.isEmpty()) {
        System.enqueueJob(new ProductServiceUpdateColumnChecker(dbns, services));
    }
}