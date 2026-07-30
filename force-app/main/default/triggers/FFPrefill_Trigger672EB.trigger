/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger672EB on Internship__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Internship__c>  newlyInsertedItems =  [SELECT  Id ,  For_supervisor_URL_real__c FROM  Internship__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Internship__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Internship__c' ,  'For_supervisor_URL_real__c' ,  'a0Y4W00003QLHcdUAH' ,  ids,null );  
 update newlyInsertedItems;}
}