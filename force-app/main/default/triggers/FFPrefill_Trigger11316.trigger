/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger11316 on OCS_Survey__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<OCS_Survey__c>  newlyInsertedItems =  [SELECT  Id ,  OCS_2024_Form_link__c FROM  OCS_Survey__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( OCS_Survey__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'OCS_Survey__c' ,  'OCS_2024_Form_link__c' ,  'a0YNv000002POVtMAO' ,  ids,null );  
 update newlyInsertedItems;}
}