/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_TriggerE92B9 on Marketing_Contacts__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Marketing_Contacts__c>  newlyInsertedItems =  [SELECT  Id ,  Schools_Email_Collection_Form_URL__c FROM  Marketing_Contacts__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Marketing_Contacts__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Marketing_Contacts__c' ,  'Schools_Email_Collection_Form_URL__c' ,  'a0YNv000000kqi0MAA' ,  ids,null );  
 update newlyInsertedItems;}
}