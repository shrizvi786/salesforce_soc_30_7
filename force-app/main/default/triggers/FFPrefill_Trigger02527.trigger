/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger02527 on NJ_Student_Data_Collection_Form__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<NJ_Student_Data_Collection_Form__c>  newlyInsertedItems =  [SELECT  Id ,  Media_release_URL__c FROM  NJ_Student_Data_Collection_Form__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( NJ_Student_Data_Collection_Form__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'NJ_Student_Data_Collection_Form__c' ,  'Media_release_URL__c' ,  'a0Y4W00000jakC1UAI' ,  ids,null );  
 update newlyInsertedItems;}
}