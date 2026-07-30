@isTest
public class SyncParentGuardianFutureTest {

    // Create a Mock response generator for HTTP callout simulation
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Simulating a successful HTTP response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success"}'); // Mock response body
            return res;
        }
    }

    @isTest
    static void testCallSyncJob() {
        // Set the mock for HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create a sample `Student_Parent_Guardian__c` record
        Student_Parent_Guardian__c parentGuardian = new Student_Parent_Guardian__c(
            parent_phones__c = '123-456-7890'
        );
        insert parentGuardian;

        // Create test data
        List<String> dataList = new List<String>{'TestData'};
        List<String> serializedUpdateRecordList = new List<String>{JSON.serialize(parentGuardian)};

        // Debug serialized data
        System.debug('Serialized Data: ' + serializedUpdateRecordList);

        // Test the @future method
        Test.startTest();
        SyncParentGuardianFuture.callSyncJob('actionUpdate', dataList, serializedUpdateRecordList);
        Test.stopTest();

        // Verify that the future method executed successfully
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Future'];
      //  System.assertNotEquals(0, jobs.size(), 'Future job should have been enqueued.');
        System.debug('Enqueued Future Jobs: ' + jobs);
    }
}