trigger SyncDashboardSubSectionRecords on Dashboard_Sub_Section__c (after insert, after update, before delete, after delete) {

  	TriggerSFSyncAPI job = new TriggerSFSyncAPI('Dashboard_Sub_Section__c', new List<String>(), '',new List<SObject>());

    if (trigger.isInsert) {

        for (Dashboard_Sub_Section__c sub : Trigger.new) {

            job.dataList.add(JSON.serialize(sub));

        }

        job.action = 'actionInsert'; // Move the action assignment outside the loop

    } else if (trigger.isUpdate) {

        for (Dashboard_Sub_Section__c sub : Trigger.new) {

          //job.dataList.add(JSON.serialize(imp));

        //UpdateData.onAfterUpdate(Trigger.new,'Subject__c' );

        job.updateRecordList.add(sub);

        }

        job.action = 'actionUpdate'; // Move the action assignment outside the loop

    } else if (trigger.isBefore && trigger.isDelete) {

        for (Dashboard_Sub_Section__c sub : Trigger.old) {

            job.dataList.add(sub.Id);

        }

        job.action = 'actionDelete'; // Move the action assignment outside the loop

    }

    if (String.isNotBlank(job.action)) {

        System.enqueueJob(job);

    }



    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

        RecentAssessmentDashboardFlagsHandler.afterDashboardSubSectionsChange(

            Trigger.new,

            Trigger.isUpdate ? Trigger.oldMap : null

        );

    }

    if (Trigger.isAfter && Trigger.isDelete) {

        RecentAssessmentDashboardFlagsHandler.afterDashboardSubSectionsDelete(Trigger.old);

    }

}