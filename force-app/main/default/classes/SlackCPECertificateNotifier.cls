public class SlackCPECertificateNotifier {

    public static void sendCPENotificationToSlack() {
        // Count for YESTERDAY
        Integer yesterdayCount = [
            SELECT COUNT()
            FROM CTLE_Credit__c
            WHERE Facilitator__r.Full_Name__c = 'Texas CPE Asynchronous'
              AND CreatedDate = YESTERDAY
        ];

        // Total Count (all time)
        Integer totalCount = [
            SELECT COUNT()
            FROM CTLE_Credit__c
            WHERE Facilitator__r.Full_Name__c = 'Texas CPE Asynchronous'
        ];

        // Make sure null is treated as 0 (although COUNT() usually doesn't return null)
        if (yesterdayCount == null) {
            yesterdayCount = 0;
        }
        if (totalCount == null) {
            totalCount = 0;
        }

        // Prepare the Slack message
        String message = 'Yesterday, SOLVED issued ' + yesterdayCount + ' CPE certificates.\n'
                       + 'All time, SOLVED issued ' + totalCount + ' CPE certificates.';

        // Call method to send this to Slack
        postToSlack(message);
    }

    private static void postToSlack(String message) {
        // String slackWebhookUrl = 'https://hooks.slack.com/services/REPLACE_WITH_SLACK_WEBHOOK'; // notification-test
         String slackWebhookUrl = 'https://hooks.slack.com/services/REPLACE_WITH_SLACK_WEBHOOK'; //	#texas-tea-cpe

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(slackWebhookUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody('{"text":"' + message.replace('"', '\\"') + '"}');

        try {
            HttpResponse response = http.send(request);
            System.debug('Slack response: ' + response.getBody());
        } catch (Exception e) {
            System.debug('Error sending to Slack: ' + e.getMessage());
        }
    }
}