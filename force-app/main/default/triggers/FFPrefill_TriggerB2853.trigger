/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_TriggerB2853 on Internship__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Internship__c>  newlyInsertedItems =  [SELECT  Id ,  Supervisor_form_URL__c FROM  Internship__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Internship__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Internship__c' ,  'Supervisor_form_URL__c' ,  'a0Y4W000030sfehUAA' ,  ids,null );  
 update newlyInsertedItems;}
}