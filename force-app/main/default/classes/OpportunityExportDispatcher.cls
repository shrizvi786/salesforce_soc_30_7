public class OpportunityExportDispatcher {
    private static Boolean queued = false;

    public static void enqueueAll() {
        if (queued) return;
        queued = true;

       PieChartExporter.sendOpportunitiesReportData();
       WorkOrderExporter.sendOpportunitiesReportData();
       PurchaseOrderExporter.sendOpportunitiesReportData();
       PendingExporter.sendOpportunitiesReportData();
       POReceivedExporter.sendOpportunitiesReportData();
        needsRenewal.sendOpportunitiesReportData();
    }
}