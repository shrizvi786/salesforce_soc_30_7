public class UpdateZoomSpreadsheetDataBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Iterable<SObject> start(Database.BatchableContext context) {
        // Query and return the records to be processed
        return [SELECT Id, School_Email_Address__c, Alternative_email__c
                FROM zoom_spreadsheet_data__c
                WHERE DAY_ONLY(CreatedDate) = TODAY AND Attended__c = 'Yes'];
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<zoom_spreadsheet_data__c> spreadsheetsToUpdate = new List<zoom_spreadsheet_data__c>();

        Set<String> emailAddresses = new Set<String>();

        for (SObject obj : scope) {
            if (obj instanceof zoom_spreadsheet_data__c) {
                zoom_spreadsheet_data__c spreadsheet = (zoom_spreadsheet_data__c)obj;

                // Collect email addresses for querying zoom_participants__c
                emailAddresses.add(spreadsheet.School_Email_Address__c);
                emailAddresses.add(spreadsheet.Alternative_email__c);
            }
        }

        // Query matching zoom_participants__c records based on email addresses
        List<zoom_participants__c> matchingParticipants = [SELECT meeting_id__c, User_Email__c
                                                           FROM zoom_participants__c
                                                           WHERE DAY_ONLY(CreatedDate) = TODAY
                                                           AND User_Email__c IN :emailAddresses];

        Map<String, String> emailToMeetingIdMap = new Map<String, String>();

        for (zoom_participants__c participant : matchingParticipants) {
            emailToMeetingIdMap.put(participant.User_Email__c, participant.meeting_id__c);
        }

        for (SObject obj : scope) {
            if (obj instanceof zoom_spreadsheet_data__c) {
                zoom_spreadsheet_data__c spreadsheet = (zoom_spreadsheet_data__c)obj;

                // Check if there is a matching participant record based on User_Email__c, School_Email_Address__c, or Alternative_email__c
                String matchingMeetingId = emailToMeetingIdMap.get(spreadsheet.School_Email_Address__c);
                if (matchingMeetingId == null) {
                    matchingMeetingId = emailToMeetingIdMap.get(spreadsheet.Alternative_email__c);
                }

                if (matchingMeetingId != null) {
                    // Update meeting_id__c on zoom_spreadsheet_data__c
                    spreadsheet.meeting_id__c = matchingMeetingId;
                    spreadsheetsToUpdate.add(spreadsheet);
                }
            }
        }

        // Update zoom_spreadsheet_data__c records
        if (!spreadsheetsToUpdate.isEmpty()) {
            try {
                update spreadsheetsToUpdate;
            } catch (Exception e) {
                System.debug('Error updating zoom_spreadsheet_data__c records: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        // Perform any post-processing logic
        // ...
    }
}