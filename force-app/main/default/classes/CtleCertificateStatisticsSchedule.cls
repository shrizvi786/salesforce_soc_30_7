public class CtleCertificateStatisticsSchedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        CtleCertificateStatistics.generateStatistics();
    }

}