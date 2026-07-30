/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger586BB on TALE_Participation__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<TALE_Participation__c>  newlyInsertedItems =  [SELECT  Id ,  Candidate_TALE_URL__c FROM  TALE_Participation__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( TALE_Participation__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'TALE_Participation__c' ,  'Candidate_TALE_URL__c' ,  'a0YNv0000027xWrMAI' ,  ids,null );  
 update newlyInsertedItems;}
}