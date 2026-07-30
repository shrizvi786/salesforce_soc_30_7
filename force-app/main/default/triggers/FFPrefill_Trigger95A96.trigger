/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger95A96 on Student_Data_Collection_Form__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Student_Data_Collection_Form__c>  newlyInsertedItems =  [SELECT  Id ,  Parent_Guardian_Home_Lang_Survey_URL__c FROM  Student_Data_Collection_Form__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Student_Data_Collection_Form__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Student_Data_Collection_Form__c' ,  'Parent_Guardian_Home_Lang_Survey_URL__c' ,  'a0Y4W00000jZQzmUAG' ,  ids,null );  
 update newlyInsertedItems;}
}