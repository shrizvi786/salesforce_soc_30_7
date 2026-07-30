@isTest
public class TestScheduleUpdateMasterContactsEmail {
    @isTest
    static void testExecute() {
        // Create a new instance of the Schedulable class
        ScheduleUpdateMasterContactsEmail scheduler = new ScheduleUpdateMasterContactsEmail();
        
        // Call the execute method directly (since it's void and doesn't return anything)
        
        scheduler.execute(null);
      
        
        // Add assertion if needed
        // For example, check if the batch job was added to the queue
        // System.assertEquals(1, [SELECT count() FROM AsyncApexJob WHERE JobType = 'BatchApex']);
    }
}