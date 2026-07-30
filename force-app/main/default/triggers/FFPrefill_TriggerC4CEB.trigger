/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_TriggerC4CEB on Student_Data_Collection_Form__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Student_Data_Collection_Form__c>  newlyInsertedItems =  [SELECT  Id ,  Media_Consent_Form_URL__c FROM  Student_Data_Collection_Form__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Student_Data_Collection_Form__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Student_Data_Collection_Form__c' ,  'Media_Consent_Form_URL__c' ,  'a0Y4W00000jZrkhUAC' ,  ids,null );  
 update newlyInsertedItems;}
}