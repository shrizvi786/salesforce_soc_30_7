/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_TriggerEF8FD on Standards_Question__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Standards_Question__c>  newlyInsertedItems =  [SELECT  Id ,  Form_URL__c FROM  Standards_Question__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Standards_Question__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Standards_Question__c' ,  'Form_URL__c' ,  'a0YNv000001LAILMA4' ,  ids,null );  
 update newlyInsertedItems;}
}