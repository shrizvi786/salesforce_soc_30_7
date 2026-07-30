global class MarketingCorrespondenceCountsSchedule implements Schedulable {
    global void execute(SchedulableContext sc)
    {
        //Invoking Batch Class with 0  offset to insert Account and Contact Activity Logs
        Integer offset = 0;
        String objectType = 'Contact';
        MarketingCorrespondenceCounts acc = new MarketingCorrespondenceCounts(offset, objectType);
        Database.executeBatch(acc);
    }
}