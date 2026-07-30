/**
 * Auto Generated and Deployed by Fast Prefill - Formstack
 **/
trigger FFPrefill_Trigger1C497 on Internship__c
    (after insert)
{
 if  (trigger.isAfter  &&  trigger.isInsert) { 
List<Internship__c>  newlyInsertedItems =  [SELECT  Id ,  Student_Timesheet_form_for_revision__c FROM  Internship__c WHERE  Id  IN :trigger.new] ; 
List<string> ids = new List<string>();
 for ( Internship__c e  : newlyInsertedItems) { 
ids.add(e.id); 
} 
 VisualAntidote.FastFormsUtilities.DoUpdateRecords( 'Internship__c' ,  'Student_Timesheet_form_for_revision__c' ,  'a0Y4W00003TgWNTUA3' ,  ids,null );  
 update newlyInsertedItems;}
}