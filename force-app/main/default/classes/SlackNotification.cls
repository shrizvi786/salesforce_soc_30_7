/*
 * ---------------------------------------------------------------------------------------------
 * Class Name     : SlackNotification
 * Test Class     : SlackNotificationTest
 * Created By     : Salesforce Developer
 * Created Date   : 2025-05-09
 * Last Modified  : 2026-03-23
 * Purpose        : Send Slack notifications from Flow based on Opportunity details.
 *                  The message is dynamically routed to the appropriate Slack channel and
 *                  group tag using ProductService keyword mapping.
 *
 * Updates:
 * 1. Added support for SalespersonId_2
 * 2. Attendance text report services route to C0AM159407N; generic "Report" keyword skips them
 * ---------------------------------------------------------------------------------------------
 */
public with sharing class SlackNotification {
    
    public class OpportunityInputWrapper {
        @InvocableVariable public Id Id;
        @InvocableVariable public String AccountFullName;
        @InvocableVariable public String DBN;
        @InvocableVariable public String ProductService;
        @InvocableVariable public String SalespersonId;
        @InvocableVariable public String SalespersonId_2;
        @InvocableVariable public Date ProductStartDate;
        @InvocableVariable public Date ProductEndDate;
        @InvocableVariable public String Type;
        @InvocableVariable public String StageName;
        @InvocableVariable public String PreviousStageName;
    }
    
    // Used for mapping services to Slack channels and group IDs
    public class SlackChannelMapping {
        public String[] services;
        public String channelId;
        public String groupId;
        
        public SlackChannelMapping(String[] services, String channelId, String groupId) {
            this.services = services;
            this.channelId = channelId;
            this.groupId = groupId;
        }
    }
    
    // Mapping: which ProductService keywords map to which Slack channel and group
    public static List<SlackChannelMapping> getChannelMappings() {
        return new List<SlackChannelMapping>{
            // Service -> Channel ID -> Group ID
            new SlackChannelMapping(new String[]{'Coaching'}, 'C01FEDPTPC4', 'S05LUK8PRLP'), // #check-in-coaching
            new SlackChannelMapping(new String[]{'App'}, 'C01FGFCET89', 'S05FCCW3EG3'), // #check-in-apps
            new SlackChannelMapping(new String[]{'Branding', 'Merchandise'}, 'C01FA1WU0QL', 'S05RU6WFNCB'), // #check-in-branding
            new SlackChannelMapping(
                new String[]{
                    'Data Dashboard',
                    'Data Dashboard ELA - Coaching',
                    'Data Dashboard Math - Coaching',
                    'Data Dashboard ELA - Work Logs',
                    'Data Dashboard Math - Work Logs'
                },
                'C01FGFBG9DX',
                'S05G27WEDA4'
            ), // #check-in-data-dashboard

            // exact match on full picklist labels (see matchesProductServiceKeyword)
            new SlackChannelMapping(
                new String[]{
                    'Monthly Attendance Text Report',
                    'Text Message Attendance Report'
                },
                'C0AM159407N',
                'S08QS0JH17T'
            ),

            // exact match only for "Events" and "Report" picklist values
            new SlackChannelMapping(new String[]{'Events', 'Report'}, 'C08MBL21N1W', 'S08QS0JH17T'), // #check-in-special-projects
            new SlackChannelMapping(new String[]{'Forms'}, 'C024D3W9TS6', 'S08QS0JH17T'), // #check-in-forms
            new SlackChannelMapping(new String[]{'Online CTLE Asynchronous Courses'}, 'C07628XKZMZ', 'S08QG4JCELA'),
            new SlackChannelMapping(new String[]{'Photography'}, 'C07LNU4FNAD', 'S07MYC0QEJH'),
            new SlackChannelMapping(new String[]{'Promo Video'}, 'C03B83NJ1EC', 'S07MUK4RAQN'),
            new SlackChannelMapping(new String[]{'Website'}, 'C027156EPS8', 'S05FR5H8L4R')
        };
    }
    
    public static SlackChannelMapping getChannelMappingForProductService(String productService) {
        if (String.isBlank(productService)) {
            return null;
        }

        List<SlackChannelMapping> mappings = getChannelMappings();

        String normalizedProductService = productService.trim();

        for (SlackChannelMapping mapping : mappings) {
            for (String keyword : mapping.services) {
                if (!matchesProductServiceKeyword(normalizedProductService, keyword)) {
                    continue;
                }

                // Exclude generic Coaching match for these specific data dashboard services
                if (keyword == 'Coaching' && (
                    normalizedProductService == 'Data Dashboard ELA - Coaching' ||
                    normalizedProductService == 'Data Dashboard Math - Coaching'
                )) {
                    continue;
                }

                return mapping;
            }
        }

        return null;
    }

    /**
     * - Single-word picklist values (Report, Events, …): exact match only, so "Report"
     *   does not match "Text Message Attendance Report".
     * - Multi-word picklist values: exact match on full Product_Service__c label.
     * - Single-word routing keywords (Coaching, App in other rows): contains.
     */
    private static Boolean matchesProductServiceKeyword(String productService, String keyword) {
        String product = productService.trim().toLowerCase();
        String key = keyword.trim().toLowerCase();

        if (key == 'report' || key == 'events' || key == 'app' || key == 'forms') {
            return product == key;
        }

        if (key.contains(' ')) {
            return product == key;
        }

        return product.contains(key);
    }
    
    @InvocableMethod(label='Send Slack Notification' description='Send Slack Notification from Flow')
    public static void sendSlackNotification(List<OpportunityInputWrapper> oppList) {
        for (OpportunityInputWrapper oppData : oppList) {
            SlackChannelMapping mapping = getChannelMappingForProductService(oppData.ProductService);

            if (mapping == null) {
                System.debug('⚠️ No matching Slack channel or group for ProductService: ' + oppData.ProductService);
                continue;
            }

            String channelId = mapping.channelId;
            String groupId = mapping.groupId;

            if (channelId == null || groupId == null) {
                System.debug('⚠️ No matching Slack channel or group for ProductService: ' + oppData.ProductService);
                continue;
            }

            String mention = '<!subteam^' + groupId + '>';
            String accountReference = oppData.DBN;

            String startDate = '';
            String endDate = '';
            String dateRange = '';

            if (oppData.ProductStartDate != null) {
                startDate = DateTime.newInstance(
                    oppData.ProductStartDate,
                    Time.newInstance(0, 0, 0, 0)
                ).format('MM/dd/yyyy');
            }

            if (oppData.ProductEndDate != null) {
                endDate = DateTime.newInstance(
                    oppData.ProductEndDate,
                    Time.newInstance(0, 0, 0, 0)
                ).format('MM/dd/yyyy');
            }

            if (!String.isBlank(startDate) && !String.isBlank(endDate)) {
                dateRange = startDate + ' - ' + endDate;
            } else if (!String.isBlank(startDate)) {
                dateRange = startDate;
            } else if (!String.isBlank(endDate)) {
                dateRange = endDate;
            }

            String salespersonText = oppData.SalespersonId;
            if (String.isBlank(salespersonText)) {
                salespersonText = 'the salesperson';
            }

            if (String.isNotBlank(oppData.SalespersonId_2)) {
                salespersonText += ' and ' + oppData.SalespersonId_2;
            }

            String message = '';

            if (oppData.StageName == 'Closed') {
                String prevStageSuffix = String.isNotBlank(oppData.PreviousStageName)
                    ? ' (from *' + oppData.PreviousStageName + '*)'
                    : '';

                message = 'Hi ' + mention + ', ' + '*' + accountReference + '*' +
                          ' has canceled their ' + '*' + oppData.ProductService + '*' +
                          ' with ' + '*' + salespersonText + '*' +
                          ' from ' + '*' + dateRange + '*' +
                          '. The opportunity is currently at ' + '*' + oppData.StageName + '*' + prevStageSuffix +
                          '. Please ensure no further work is done for the specific date range on this service unless indicated otherwise.';
            }
            else if (oppData.StageName == 'Pending') {
                message = 'Hi ' + mention + ', ' + '*' + accountReference + '*' +
                          ' has not fully committed to purchasing ' + '*' + oppData.ProductService + '*' +
                          ' with ' + '*' + salespersonText + '*' +
                          ' from ' + '*' + dateRange + '*' +
                          '. The opportunity is currently at ' + '*' + oppData.StageName + '*' +
                          '. Please check with ' + '*' + salespersonText + '*' +
                          ' on whether to continue providing this service or not in the corresponding channel.';
            }
            else if (oppData.Type == 'Renewal Revenue' && oppData.StageName != 'Pending') {
                message = mention + ', ' + '*' + accountReference + '*' +
                          ' has renewed their ' + '*' + oppData.ProductService + '*' +
                          ' with ' + '*' + salespersonText + '*' +
                          ' from ' + '*' + dateRange + '*' +
                          '. The opportunity is currently at ' + '*' + oppData.StageName + '*' +
                          '. Please follow steps to ensure successful CX for this renewal in the corresponding channel.';
            }
            else if (oppData.Type == 'New Revenue' && oppData.StageName != 'Pending') {
                message = 'Hi ' + mention + ', ' + '*' + accountReference + '*' +
                          ' has purchased a new ' + '*' + oppData.ProductService + '*' +
                          ' with ' + '*' + salespersonText + '*' +
                          ' from ' + '*' + dateRange + '*' +
                          '. The opportunity is currently at ' + '*' + oppData.StageName + '*' +
                          '. Please follow steps to ensure successful CX for this new service in the corresponding channel.';
            }

            if (!String.isEmpty(message)) {
                sendSlackMessageViaBot(message, channelId);
            }
        }
    }
    
    @future(callout=true)
    public static void sendSlackMessageViaBot(String message, String channelId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://slack.com/api/chat.postMessage');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer REPLACE_WITH_SLACK_BOT_TOKEN');
        
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('channel', channelId);
        payload.put('text', message);
        payload.put('link_names', 1);
        
        req.setBody(JSON.serialize(payload));
        
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('✅ Slack API Response for channel ' + channelId + ': ' + res.getBody());
        } catch (Exception e) {
            System.debug('❌ Slack API call failed for channel ' + channelId + ': ' + e.getMessage());
        }
    }
}