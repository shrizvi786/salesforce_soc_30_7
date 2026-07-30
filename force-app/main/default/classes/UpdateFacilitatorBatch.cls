global class UpdateFacilitatorBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, meeting_id__c FROM zoom_facilitator__c where DAY_ONLY(CreatedDate) = TODAY';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<zoom_facilitator__c> scope) {
        List<TALE_Participation__c> recordsToUpdate = new List<TALE_Participation__c>();

        // Map to store meeting_id__c and corresponding Name from zoom_facilitator__c
        Map<String, String> meetingIdToNameMap = new Map<String, String>();
        for (zoom_facilitator__c facilitator : scope) {
            meetingIdToNameMap.put(facilitator.meeting_id__c, facilitator.Name);
        }

        // Query Contact records based on Name
        Map<String, Id> nameToContactIdMap = new Map<String, Id>();
        for (Contact contact : [SELECT Id, Name FROM Contact WHERE Name IN :meetingIdToNameMap.values() AND RecordType.Name = 'Consultant/Facilitator']) {
            nameToContactIdMap.put(contact.Name, contact.Id);
        }

        // Query TALE_Participation__c records where meeting_id__c matches
        List<TALE_Participation__c> matchingRecords = [SELECT Id, meeting_id__c, Facilitator__c
                                                       FROM TALE_Participation__c
                                                       WHERE meeting_id__c IN :meetingIdToNameMap.keySet() AND DAY_ONLY(CreatedDate) = TODAY];

        // Update Facilitator__c field with the corresponding Contact Id
        for (TALE_Participation__c participation : matchingRecords) {
            String facilitatorName = meetingIdToNameMap.get(participation.meeting_id__c);
            if (nameToContactIdMap.containsKey(facilitatorName)) {
                participation.Facilitator__c = nameToContactIdMap.get(facilitatorName);
                recordsToUpdate.add(participation);
            }
        }

        // Update records
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Optional: Add any finishing logic here
    }
}