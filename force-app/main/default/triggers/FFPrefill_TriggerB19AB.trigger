/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_TriggerB19AB on OCS_MOY_EOY__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<OCS_MOY_EOY__c>  newlyInsertedItems =  [SELECT  Id ,  Submitted_Form_URL__c FROM  OCS_MOY_EOY__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( OCS_MOY_EOY__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'OCS_MOY_EOY__c' ,  'Submitted_Form_URL__c' ,  'a0YNv00000PZIdCMAX' ,  ids,null );  
 update newlyInsertedItems;}
}