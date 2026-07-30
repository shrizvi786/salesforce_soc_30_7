/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger5492B on Internship__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Internship__c>  newlyInsertedItems =  [SELECT  Id ,  Sup_Form_URL_Test__c FROM  Internship__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Internship__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Internship__c' ,  'Sup_Form_URL_Test__c' ,  'a0YNv00000UpLdzMAF' ,  ids,null );  
 update newlyInsertedItems;}
}