@isTest
public class syncStaffPrincipalRecordToContactTest {

    @isTest
    static void queueable_startsPrincipalBatch() {
        String uniqueEmail = 'principal.queue.' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@schools.nyc.gov';
        Map<String, Object> apiBody = new Map<String, Object>{
            'body' => new List<Object>{
                new Map<String, Object>{
                    'FirstName' => 'PF',
                    'LastName' => 'PL',
                    'Teacher_Email__c' => uniqueEmail
                }
            },
            'lastFetchedOsisId' => 1
        };

        Test.setMock(HttpCalloutMock.class, new PrincipalApiMock(JSON.serialize(apiBody)));
        Test.startTest();
        System.enqueueJob(new syncStaffPrincipalRecordToContact(0));
        Test.stopTest();

        List<Contact> found = [SELECT Id FROM Contact WHERE Teacher_Email__c = :uniqueEmail LIMIT 1];
        System.assertEquals(1, found.size());
    }

    private class PrincipalApiMock implements HttpCalloutMock {
        private final String jsonBody;
        PrincipalApiMock(String jsonBody) {
            this.jsonBody = jsonBody;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            String ep = req.getEndpoint();
            if (ep != null && ep.contains('get_staff_data_principal')) {
                res.setBody(jsonBody);
                return res;
            }
            if (ep != null && ep.contains('save-records')) {
                res.setBody('{"ok":true}');
                return res;
            }
            res.setBody('{}');
            return res;
        }
    }
}