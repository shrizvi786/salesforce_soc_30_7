trigger Trigger_AccountMonday on Account (
    after insert,
    after update,
    after delete
) {

    if (Trigger.isAfter) {

        // INSERT + UPDATE
        if (Trigger.isInsert || Trigger.isUpdate) {

            Set<Id> accountIds = new Set<Id>();

            if (Trigger.isInsert) {
                accountIds = Trigger.newMap.keySet();
            }

            if (Trigger.isUpdate) {
               // accountIds.addAll(Trigger.newMap.keySet());

                // Optional: only sync if DBN or District changed
                for (Id accId : Trigger.newMap.keySet()) {

                    Account newAcc = Trigger.newMap.get(accId);
                    Account oldAcc = Trigger.oldMap.get(accId);

                    if (
                        newAcc.DBN__c != oldAcc.DBN__c ||
                        newAcc.District__c != oldAcc.District__c
                    ) {
                        accountIds.add(accId);
                    }
                } 
            }

            if (!accountIds.isEmpty()) {
                System.enqueueJob(
                    new Sync_AccountMonday(accountIds, 'UPSERT')
                );
            }
        }

        // DELETE
        if (Trigger.isDelete) {

            System.enqueueJob(
                new Sync_AccountMonday(
                    Trigger.oldMap.keySet(),
                    'DELETE'
                )
            );
        }
    }
}