//Class to schedule student object batches to sync bulk records
//
public class SyncBulkStudentRecordsScheduler implements Queueable {
    public List<Id> accountIdList;  // List to hold School IDs to process
    
    // Constructor to initialize the list of School IDs to process
    public SyncBulkStudentRecordsScheduler(List<Id> accountIdList) {
        this.accountIdList = accountIdList;
    }
    
    public void execute(QueueableContext context) {
        // Check if there are account ids to sync student records of
        if (!accountIdList.isEmpty()) {
            
            // Retrieve and remove the first School ID from the List
            String accountId = accountIdList.remove(0);           
            System.debug('accountIdList' + accountIdList.size());
            
            //Calling the class for each School 
            //SyncButtonBulkRecordScheduleClass fetches all student records of account id to sync
            SyncButtonBulkRecordScheduleClass batchClass = new SyncButtonBulkRecordScheduleClass(accountId, 'Student__c', 'School__c');
            Database.executeBatch(batchClass, 100);
            
            // Enqueue the next job if there are remaining account IDs
            // If all the school id are process it will process else part.
            if (!accountIdList.isEmpty()) {
                
                //Get the Number of Hold batches
                List<AsyncApexJob> queuedJob = [SELECT Id, Status, ApexClassId FROM AsyncApexJob WHERE Status = 'Holding' and JobType = 'BatchApex'];
                System.debug('Number of queued jobs batch apex: ' + queuedJob.size());
                
                //Move batches to queue if hold batches are <50
                if(queuedJob.size() < 50){
                    //Enqueing the class at delay of 1 min
                    if(!Test.isRunningTest()){
                        Integer delayInMinutes = 1;
                        System.enqueueJob(new SyncBulkStudentRecordsScheduler(accountIdList), delayInMinutes); 
                    }                    
                }
                //Wait 10 mins if hold batches >=50 and retry to move batches after 10 mins
                else{
                    //Enqueing the class at delay of 10 min when there are 50 batchs are already on holding Status
                    Integer delayInMinute = 10;
                    System.enqueueJob(new SyncBulkStudentRecordsScheduler(accountIdList), delayInMinute);
                }              
            }else{
                System.debug('All Students Synced');
            }
        }
    }
}