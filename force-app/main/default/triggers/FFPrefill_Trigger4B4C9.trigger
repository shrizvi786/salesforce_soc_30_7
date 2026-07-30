/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger4B4C9 on Student_Data_Collection_Form__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Student_Data_Collection_Form__c>  newlyInsertedItems =  [SELECT  Id ,  Student_Ethnicity_URL__c FROM  Student_Data_Collection_Form__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Student_Data_Collection_Form__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Student_Data_Collection_Form__c' ,  'Student_Ethnicity_URL__c' ,  'a0Y4W00000jZQuNUAW' ,  ids,null );  
 update newlyInsertedItems;}
}