/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_TriggerF8D25 on NJ_Student_Data_Collection_Form__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<NJ_Student_Data_Collection_Form__c>  newlyInsertedItems =  [SELECT  Id ,  Off_Site_Form_URL__c FROM  NJ_Student_Data_Collection_Form__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( NJ_Student_Data_Collection_Form__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'NJ_Student_Data_Collection_Form__c' ,  'Off_Site_Form_URL__c' ,  'a0Y4W00000jajMZUAY' ,  ids,null );  
 update newlyInsertedItems;}
}