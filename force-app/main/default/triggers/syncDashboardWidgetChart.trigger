trigger syncDashboardWidgetChart on Dashboard_Widget_Charts__c (after insert, after update, before delete) {
    TriggerSFSyncAPI job = new TriggerSFSyncAPI('Dashboard_Widget_Charts__c', new List<String>(), '',new List<SObject>());
    
    if (trigger.isInsert) {
        for (Dashboard_Widget_Charts__c widgetChart : Trigger.new) {
            job.dataList.add(JSON.serialize(widgetChart));
        }
        job.action = 'actionInsert'; 
    } else if (trigger.isUpdate) {
        for (Dashboard_Widget_Charts__c widgetChart : Trigger.new) {
            job.updateRecordList.add(widgetChart);
        }
        job.action = 'actionUpdate'; 
    } else if (trigger.isDelete) {
        for (Dashboard_Widget_Charts__c widgetChart : Trigger.old) {
            job.dataList.add(widgetChart.Id);
        }
        job.action = 'actionDelete'; 
    }
    System.enqueueJob(job);  
}