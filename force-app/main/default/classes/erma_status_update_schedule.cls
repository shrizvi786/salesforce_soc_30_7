/* Test class name = ScheduledErmaStatusUpdateTest  */
global class erma_status_update_schedule implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        erma_status_update job = new erma_status_update();
        System.enqueueJob(job);
    }
}