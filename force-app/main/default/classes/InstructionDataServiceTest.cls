@isTest
private class InstructionDataServiceTest {

    // Mock class for the HTTP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(JSON.serialize(
                new Map<String, Object>{
                    'body' => new Map<String, Object>{
                        'systemQueryInstructions' => 'Updated System Query Instructions',
                        'natureLanguageInstructions' => 'Updated Natural Language Instructions'
                    }
                }
            ));
            return res;
        }
    }

    @isTest
    static void testInstructionDataServiceFlow() {
        // Create test data
        Data_Plus_Instructions__c activeInstruction = new Data_Plus_Instructions__c(
            
            System_Query_Instructions_Doc__c = 'http://old-system-url.com/doc1',
            Nature_Language_Instructions_Doc__c = 'http://old-nature-url.com/doc2',
            Active_Production__c = true
        );
        insert activeInstruction;

        // Create a second record that will be updated by the class
        Data_Plus_Instructions__c recordToUpdate = new Data_Plus_Instructions__c(
           
            Active_Production__c = false
        );
        insert recordToUpdate;

        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Start the test context
        Test.startTest();
        InstructionDataService.fetchInstructions(new List<Id>{recordToUpdate.Id});
        Test.stopTest();

        // Verify the record was updated
        Data_Plus_Instructions__c updated = [SELECT Id, System_Query_Instructions_Doc__c, Nature_Language_Instructions_Doc__c, Status__c 
                                             FROM Data_Plus_Instructions__c 
                                             WHERE Id = :recordToUpdate.Id];
        System.assertEquals('Updated System Query Instructions', updated.System_Query_Instructions_Doc__c);
        System.assertEquals('Updated Natural Language Instructions', updated.Nature_Language_Instructions_Doc__c);
        System.assertEquals('Draft', updated.Status__c);
    }
}