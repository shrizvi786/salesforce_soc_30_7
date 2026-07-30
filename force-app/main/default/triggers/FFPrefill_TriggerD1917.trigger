/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_TriggerD1917 on Student_Data_Collection_Form__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Student_Data_Collection_Form__c>  newlyInsertedItems =  [SELECT  Id ,  Blue_Card_URL__c FROM  Student_Data_Collection_Form__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Student_Data_Collection_Form__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Student_Data_Collection_Form__c' ,  'Blue_Card_URL__c' ,  'a0Y4W00000GTmYNUA1' ,  ids,null );  
 update newlyInsertedItems;}
}