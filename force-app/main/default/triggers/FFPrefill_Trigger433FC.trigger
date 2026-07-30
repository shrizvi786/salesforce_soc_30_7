/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger433FC on Student_Data_Collection_Form__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Student_Data_Collection_Form__c>  newlyInsertedItems =  [SELECT  Id ,  COVID_19_Form_URL__c FROM  Student_Data_Collection_Form__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Student_Data_Collection_Form__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Student_Data_Collection_Form__c' ,  'COVID_19_Form_URL__c' ,  'a0Y4W00000jZvNvUAK' ,  ids,null );  
 update newlyInsertedItems;}
}