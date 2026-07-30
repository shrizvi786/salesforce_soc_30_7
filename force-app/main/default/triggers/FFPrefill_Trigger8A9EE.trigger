/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger8A9EE on NJ_Student_Data_Collection_Form__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<NJ_Student_Data_Collection_Form__c>  newlyInsertedItems =  [SELECT  Id ,  Emergency_Contact_URL__c FROM  NJ_Student_Data_Collection_Form__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( NJ_Student_Data_Collection_Form__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'NJ_Student_Data_Collection_Form__c' ,  'Emergency_Contact_URL__c' ,  'a0Y4W00000HnmEjUAJ' ,  ids,null );  
 update newlyInsertedItems;}
}