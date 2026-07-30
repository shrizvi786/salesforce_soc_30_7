public class SyncMiniClipSchoolIds implements Queueable{
    public List<Id> SchoolIdList;  // List to hold School IDs to process
    
    // Constructor to initialize the list of School IDs to process
    public SyncMiniClipSchoolIds(List<Id> SchoolIdList) {
        this.SchoolIdList = SchoolIdList;
    }
    
    public void execute(QueueableContext context) {
        // Check if there are SchoolIdList ids to sync
        if (!SchoolIdList.isEmpty()) {
            
            // Retrieve and remove the first School ID from the List
            String schoolId = SchoolIdList.remove(0);           
            System.debug('SchoolIdList' + SchoolIdList.size());
            System.debug('SchoolId::::::::::' + SchoolIdList);
            
            //Calling the class for each School 
            SyncMiniClipTotalLikeShare batchClass = new SyncMiniClipTotalLikeShare(schoolId);
            Database.executeBatch(batchClass);
            
            // Enqueue the next job if there are remaining account IDs
            // If all the school id are process it will process else part.
            if (!SchoolIdList.isEmpty()) {
                
                //Get the Number of Hold batches
                List<AsyncApexJob> queuedJob = [SELECT Id, Status, ApexClassId FROM AsyncApexJob WHERE Status = 'Holding' and JobType = 'BatchApex'];
                System.debug('Number of queued jobs batch apex: ' + queuedJob.size());
                
                //Move batches to queue if hold batches are <50
                if(queuedJob.size() < 50){
                    //Enqueing the class at delay of 1 min
                    //Here we comment the if condition because of test class
                    if(!Test.isRunningTest()){
                        Integer delayInMinutes = 1;
                        System.enqueueJob(new SyncMiniClipSchoolIds(SchoolIdList)); 
                    }                    
                }
                //Wait 10 mins if hold batches >=50 and retry to move batches after 10 mins
                else{
                    //Enqueing the class at delay of 10 min when there are 50 batchs are already on holding Status
                    Integer delayInMinute = 10;
                    System.enqueueJob(new SyncMiniClipSchoolIds(SchoolIdList), delayInMinute);
                }              
            }else{
                System.debug('All MiniClip Synced');
            }
        }
    }
}