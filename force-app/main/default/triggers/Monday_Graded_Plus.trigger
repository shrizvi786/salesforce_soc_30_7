/*
Test Class Name : Monday_Graded_Plus_Test
 Class Name : Monday_Graded_Plus
Test class Name of this particular test : Monday_Graded_Plus_Trigger_Test
*/
trigger Monday_Graded_Plus on Account (after insert, after update) {
    List<Id> accountIdsToSend = new List<Id>();

    for (Account acc : Trigger.new) {
       if ((Trigger.isInsert || (Trigger.isUpdate && acc.GRADED_Logins__c != Trigger.oldMap.get(acc.Id).GRADED_Logins__c))
            && acc.GRADED_Logins__c != null && acc.GRADED_Logins__c != 0) {
            
            accountIdsToSend.add(acc.Id);
        }
    }

    if (!accountIdsToSend.isEmpty()) {
        Monday_Graded_Plus.sendAccountData(accountIdsToSend);
    }

}