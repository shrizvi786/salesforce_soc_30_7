@isTest
public class syncBulkStudentRecordsScheduleTest {
@isTest
    public static void testScheduledJob() {
        // Enqueue the scheduled job
        Test.startTest();
        
        Datetime nextRunTime = Datetime.now().addMinutes(1);
        String cronExpression = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year();
        System.schedule('Test Batch Job', cronExpression, new syncBulkStudentRecordsSchedule());
        
        Test.stopTest();       
    }
}