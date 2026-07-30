trigger SyncProductService on Product_Service_Update__c (after insert, after update, before delete) {

    /*if(trigger.isbefore && trigger.isdelete){
// If the item is being deleted.
for(Contact contact : Trigger.old) {
System.debug('The item is being deleted.');
System.debug(contact);
TriggerSFSyncAPI.triggerAPICall('Contact', contact.Id, 'actionDelete');
}
}else{
// If the item is being created or updated.
for(Contact contact : Trigger.New) {
System.debug('The item is being created or updated.');
System.debug(contact);
if(trigger.isinsert){
TriggerSFSyncAPI.triggerAPICall('Contact',JSON.serialize(contact),'actionInsert');     
}else{
//TriggerSFSyncAPI.triggerAPICall('Contact',contact.Id,'actionUpdate');
// remove the api calling from TriggerSFSyncAPI for update records(Update on 13/1/2023)
//TriggerSFSyncAPI.triggerAPICall('Contact',JSON.serialize(contact), 'actionUpdate');
TriggerSFSyncAPI.sendData('Contact',JSON.serialize(contact),'actionUpdate');  
}
}   
}*/
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Product_Service_Update__c', new List<String>(), '',new List<SObject>());
    if (trigger.isInsert) {
        for (Product_Service_Update__c ctle : Trigger.new) {
            job.dataList.add(JSON.serialize(ctle));
        }
        job.action = 'actionInsert'; // Move the action assignment outside the loop
    } else if (trigger.isUpdate) {
        for (Product_Service_Update__c ctle : Trigger.new) {
            job.updateRecordList.add(ctle);
        }
        job.action = 'actionUpdate'; // Move the action assignment outside the loop
    } else if (trigger.isDelete) {
        for (Product_Service_Update__c ctle : Trigger.old) {
            job.dataList.add(ctle.Id);
        }
        job.action = 'actionDelete'; // Move the action assignment outside the loop
    }
    System.enqueueJob(job);    
    
}