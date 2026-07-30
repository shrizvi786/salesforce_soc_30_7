/*
 * ---------------------------------------------------------------------------------------------
 * Class Name     : OpportunityStageChangeNotifier
 * Test Class     : OpportunityStageChangeNotifierTest
 * Created By     : Salesforce Developer
 * Created Date   : 2025-05-26
 * Last Modified  : 2026-03-24
 * Purpose        : Sends Slack notifications to specific channels when Opportunity stage changes.
 *
 * Updates:
 * 1. Added support for Salesperson_2
 * 2. If Salesperson_2 is blank, only Salesperson is included in the Slack message
 * ---------------------------------------------------------------------------------------------
 */
public with sharing class OpportunityStageChangeNotifier {

    public class StageChangeInput {
        @InvocableVariable public String DBN;
        @InvocableVariable public String OpportunityName;
        @InvocableVariable public Decimal Amount;
        @InvocableVariable public String PreviousStage;
        @InvocableVariable public String NewStage;
        @InvocableVariable public String Salesperson;      // Slack User ID
        @InvocableVariable public String Salesperson_2;    // Slack User ID (optional)
        @InvocableVariable public String SlackChannelId;   // Slack Channel ID
    }

    @InvocableMethod(label='Notify Opportunity Stage Change' description='Send Slack notification when Opportunity changes stage')
    public static void notifyStageChange(List<StageChangeInput> inputList) {
        System.debug('🔔 Slack Stage Change Notification Input: ' + inputList);
        
        for (StageChangeInput input : inputList) {
            String message = generateMessage(input);
            sendSlackMessage(message, input.SlackChannelId);
        }
    }

    private static String generateMessage(StageChangeInput input) {
        String amountString = input.Amount != null
            ? '$' + String.valueOf(input.Amount)
            : 'an unspecified amount';

        String ccText = buildSalespersonMention(input.Salesperson, input.Salesperson_2);
        
        return input.DBN + '’s *' + input.OpportunityName + '* opportunity for *' +
               amountString + '* moved from *' + input.PreviousStage +
               '* to *' + input.NewStage + '*.' + ccText;
    }

    private static String buildSalespersonMention(String salesperson1, String salesperson2) {
        List<String> mentions = new List<String>();

        if (String.isNotBlank(salesperson1)) {
            mentions.add('<@' + salesperson1 + '>');
        }

        if (String.isNotBlank(salesperson2)) {
            mentions.add('<@' + salesperson2 + '>');
        }

        if (mentions.isEmpty()) {
            return '';
        }

        return ' CC ' + String.join(mentions, ' ');
    }

    @future(callout=true)
    private static void sendSlackMessage(String message, String channelId) {
        System.debug('📤 Sending to Slack Channel ' + channelId + ': ' + message);
        Boolean success = trySendSlackMessage(message, channelId);
        
        if (!success) {
            System.debug('🔄 Attempting to invite bot to channel and retry...');
            Boolean invited = inviteBotToChannel(channelId);
            
            if (invited) {
                trySendSlackMessage(message, channelId);
            } else {
                System.debug('❌ Failed to invite bot to Slack channel: ' + channelId);
            }
        }
    }

    private static Boolean trySendSlackMessage(String message, String channelId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://slack.com/api/chat.postMessage');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer REPLACE_WITH_SLACK_BOT_TOKEN');

        Map<String, Object> body = new Map<String, Object>{
            'channel' => channelId,
            'text' => message,
            'link_names' => 1
        };
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('📬 Slack chat.postMessage response: ' + res.getBody());

            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            if (result.containsKey('ok') && result.get('ok') == true) {
                return true;
            }

            if (result.containsKey('error') && String.valueOf(result.get('error')) == 'not_in_channel') {
                return false;
            }
        } catch (Exception e) {
            System.debug('❌ Exception while sending Slack message: ' + e.getMessage());
        }

        return false;
    }
    
    private static Boolean inviteBotToChannel(String channelId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://slack.com/api/conversations.join');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer REPLACE_WITH_SLACK_BOT_TOKEN');

        Map<String, Object> body = new Map<String, Object>{
            'channel' => channelId
        };
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('🔗 Slack conversations.join response: ' + res.getBody());

            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return result.containsKey('ok') && result.get('ok') == true;
        } catch (Exception e) {
            System.debug('❌ Exception while joining Slack channel: ' + e.getMessage());
        }

        return false;
    }
}