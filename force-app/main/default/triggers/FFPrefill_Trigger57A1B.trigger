/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger57A1B on Registration__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Registration__c>  newlyInsertedItems =  [SELECT  Id ,  Scholarship_Gala_PO_Check_Form__c FROM  Registration__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Registration__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Registration__c' ,  'Scholarship_Gala_PO_Check_Form__c' ,  'a0Y4W00003QSueaUAD' ,  ids,null );  
 update newlyInsertedItems;}
}