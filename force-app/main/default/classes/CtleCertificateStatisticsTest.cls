@isTest(SeeAllData=false)
public class CtleCertificateStatisticsTest {

    @isTest(SeeAllData=false)
    static void testGenerateStatistics() {
          // Mock callout
        system.Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method
        CtleCertificateStatistics.generateStatistics();
        // Create test records for today
        List<TALE_Participation__c> testRecords = new List<TALE_Participation__c>();
       // for(Integer i = 0; i < 5; i++) {
            TALE_Participation__c record = new TALE_Participation__c(
                Email__c = 'test@example.com',
                Borough__c = 'Manhattan'
            );
            testRecords.add(record);
     //   }
        insert testRecords;

      
    }

    // Inner class to mock the HTTP response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('Mock response');
            return res;
        }
    }
}