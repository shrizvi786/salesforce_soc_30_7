/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger757FD on Registration__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Registration__c>  newlyInsertedItems =  [SELECT  Id ,  NYSALAS_Partnership_Check_Upload__c FROM  Registration__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Registration__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Registration__c' ,  'NYSALAS_Partnership_Check_Upload__c' ,  'a0Y4W00003QSuepUAD' ,  ids,null );  
 update newlyInsertedItems;}
}