/*
    * Author : Lakhan Singh Thakur
    * Date : 10 Sep 2024
    * @description This class schedules the daily execution of various report methods, 
    * including sending monthly amounts to APIs for opportunities and different accrual reports.
*/
global class AccrualReportScheduler implements Schedulable {

    global void execute(SchedulableContext sc) {
        OpportunityMonthlyAmountsSender.sendMonthlyAmountsToApi();
        AccrualCoachingReport.sendMonthlyAmountsToApi();
        AccrualOtherServicesReport.sendMonthlyAmountsToApi();
        AccrualTaleReport.sendMonthlyAmountsToApi();
    }
}