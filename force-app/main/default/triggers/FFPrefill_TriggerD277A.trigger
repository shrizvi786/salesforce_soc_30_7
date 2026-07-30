/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_TriggerD277A on Registration__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Registration__c>  newlyInsertedItems =  [SELECT  Id ,  Ellis_Intake_Form_Url__c FROM  Registration__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Registration__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Registration__c' ,  'Ellis_Intake_Form_Url__c' ,  'a0YNv000001FE26MAG' ,  ids,null );  
 update newlyInsertedItems;}
}