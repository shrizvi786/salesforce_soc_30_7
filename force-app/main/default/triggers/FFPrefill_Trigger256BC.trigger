/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger256BC on Registration__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Registration__c>  newlyInsertedItems =  [SELECT  Id ,  Cancellation_URL__c FROM  Registration__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Registration__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Registration__c' ,  'Cancellation_URL__c' ,  'a0Y4W00000JO1UgUAL' ,  ids,null );  
 update newlyInsertedItems;}
}