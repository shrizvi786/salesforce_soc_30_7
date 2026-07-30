/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger162A6 on OCS_RFP__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<OCS_RFP__c>  newlyInsertedItems =  [SELECT  Id ,  Invite_URL__c FROM  OCS_RFP__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( OCS_RFP__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'OCS_RFP__c' ,  'Invite_URL__c' ,  'a0Y4W00003RIBN3UAP' ,  ids,null );  
 update newlyInsertedItems;}
}