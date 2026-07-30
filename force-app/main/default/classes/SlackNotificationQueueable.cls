public class SlackNotificationQueueable implements Queueable, Database.AllowsCallouts {
    private Id payrollId;
    private String messageDetail;

    public SlackNotificationQueueable(Id payrollId, String messageDetail) {
        this.payrollId = payrollId;
        this.messageDetail = messageDetail;
    }

    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://hooks.slack.com/services/REPLACE_WITH_SLACK_WEBHOOK');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        String message = '🚨 Payroll Notification\nPayroll ID: ' + payrollId + '\nDetails: ' + messageDetail;
        req.setBody(JSON.serialize(new Map<String, Object>{ 'text' => message }));

        try {
            HttpResponse res = http.send(req);
            System.debug('Slack Response: ' + res.getBody());
        } catch (Exception ex) {
            System.debug('Slack Notification Failed (Async): ' + ex.getMessage());
        }
    }
}