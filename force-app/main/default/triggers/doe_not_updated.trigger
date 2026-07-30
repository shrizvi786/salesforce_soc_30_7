trigger doe_not_updated on Contact (after update) {
    // List to hold contacts where DOE_Not_Updated__c has been changed
    List<Id> contactIdsToUpdate = new List<Id>();
    
    for (Contact con : Trigger.new) {
        // Check if DOE_Not_Updated__c field has been changed
        if (con.DOE_Not_Updated__c != Trigger.oldMap.get(con.Id).DOE_Not_Updated__c) {
            contactIdsToUpdate.add(con.Id);
        }
    }
    
    if (!contactIdsToUpdate.isEmpty()) {
        // Call the method from the separate class to send data to the API
        doe_not_updated_class.send(contactIdsToUpdate);
    }
}