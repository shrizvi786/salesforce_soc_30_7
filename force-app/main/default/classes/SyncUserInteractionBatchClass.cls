global class SyncUserInteractionBatchClass implements Schedulable{
    global void execute(SchedulableContext ctx) {
        System.debug('Calling UserInteraction.doAreaCalloutAsync()'); 
        if(Test.isRunningTest()==true){
            system.debug('Inside if');
        	SyncNewsInteraction_Bulk_API.doAreaCallout(true);
        	SyncSocialInteraction_Bulk_API.doAreaCallout(true);
            SyncGradedInteraction_Bulk_API.doAreaCallout(true);
            SyncGradedStandaloneInteraction_Bulk_API.doAreaCallout(true);
        }else{
            system.debug('Inside else');
            SyncNewsInteraction_Bulk_API.doAreaCallout(false);
        	SyncSocialInteraction_Bulk_API.doAreaCallout(false);
            SyncGradedInteraction_Bulk_API.doAreaCallout(false);
            SyncGradedStandaloneInteraction_Bulk_API.doAreaCallout(false);
        }    
     }
}