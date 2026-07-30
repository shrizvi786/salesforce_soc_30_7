/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger698A8 on Internship__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Internship__c>  newlyInsertedItems =  [SELECT  Id ,  Enrichment_URL_Student__c FROM  Internship__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Internship__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Internship__c' ,  'Enrichment_URL_Student__c' ,  'a0Y4W00003ThhxmUAB' ,  ids,null );  
 update newlyInsertedItems;}
}