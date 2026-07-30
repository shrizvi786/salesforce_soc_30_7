@isTest
private class OpportunityStageChangeNotifierTest {

    // Mock class to simulate Slack API responses
    private class SlackHttpMock implements HttpCalloutMock {
        private Boolean simulateNotInChannel;
        private Boolean simulateJoinSuccess;

        public SlackHttpMock(Boolean simulateNotInChannel, Boolean simulateJoinSuccess) {
            this.simulateNotInChannel = simulateNotInChannel;
            this.simulateJoinSuccess = simulateJoinSuccess;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('chat.postMessage')) {
                if (simulateNotInChannel) {
                    res.setBody('{"ok": false, "error": "not_in_channel"}');
                } else {
                    res.setBody('{"ok": true}');
                }
            } else if (req.getEndpoint().contains('conversations.join')) {
                if (simulateJoinSuccess) {
                    res.setBody('{"ok": true}');
                } else {
                    res.setBody('{"ok": false, "error": "cant_invite"}');
                }
            }
            
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testNotifyStageChange_Success() {
        Test.setMock(HttpCalloutMock.class, new SlackHttpMock(false, false));

        OpportunityStageChangeNotifier.StageChangeInput input = new OpportunityStageChangeNotifier.StageChangeInput();
        input.DBN = 'ACME Corp';
        input.OpportunityName = 'Expansion Deal';
        input.Amount = 50000;
        input.PreviousStage = 'Prospecting';
        input.NewStage = 'Negotiation';
        input.Salesperson = 'U123456';
        input.SlackChannelId = 'C987654';

        Test.startTest();
        OpportunityStageChangeNotifier.notifyStageChange(new List<OpportunityStageChangeNotifier.StageChangeInput>{ input });
        Test.stopTest();
    }

    @isTest
    static void testNotifyStageChange_BotNotInChannel_RetrySuccess() {
        Test.setMock(HttpCalloutMock.class, new SlackHttpMock(true, true));

        OpportunityStageChangeNotifier.StageChangeInput input = new OpportunityStageChangeNotifier.StageChangeInput();
        input.DBN = 'Globex';
        input.OpportunityName = 'Renewal';
        input.Amount = 100000;
        input.PreviousStage = 'Proposal';
        input.NewStage = 'Closed Won';
        input.Salesperson = 'U543210';
        input.SlackChannelId = 'C123456';

        Test.startTest();
        OpportunityStageChangeNotifier.notifyStageChange(new List<OpportunityStageChangeNotifier.StageChangeInput>{ input });
        Test.stopTest();
    }

    @isTest
    static void testNotifyStageChange_BotInviteFails() {
        Test.setMock(HttpCalloutMock.class, new SlackHttpMock(true, false));

        OpportunityStageChangeNotifier.StageChangeInput input = new OpportunityStageChangeNotifier.StageChangeInput();
        input.DBN = 'Initech';
        input.OpportunityName = 'Contract Upgrade';
        input.Amount = 75000;
        input.PreviousStage = 'Qualification';
        input.NewStage = 'Proposal';
        input.Salesperson = 'U777777';
        input.SlackChannelId = 'C999999';

        Test.startTest();
        OpportunityStageChangeNotifier.notifyStageChange(new List<OpportunityStageChangeNotifier.StageChangeInput>{ input });
        Test.stopTest();
    }
}