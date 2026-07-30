@isTest
public class syncStaffRecordToContactTest {

    @isTest
    static void queueable_startsStaffBatch() {
        String uniqueEmail = 'staff.queue.' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@schools.nyc.gov';
        Map<String, Object> apiBody = new Map<String, Object>{
            'body' => new List<Object>{
                new Map<String, Object>{
                    'FirstName' => 'QF',
                    'LastName' => 'QL',
                    'Email' => uniqueEmail
                }
            },
            'lastFetchedOsisId' => 1
        };

        Test.setMock(HttpCalloutMock.class, new StaffApiMock(JSON.serialize(apiBody)));
        Test.startTest();
        System.enqueueJob(new syncStaffRecordToContact(0));
        Test.stopTest();

        List<Contact> found = [SELECT Id FROM Contact WHERE Teacher_Email__c = :uniqueEmail LIMIT 1];
        System.assertEquals(1, found.size(), 'Queueable should run batch and upsert Contact');
    }

    private class StaffApiMock implements HttpCalloutMock {
        private final String jsonBody;
        StaffApiMock(String jsonBody) {
            this.jsonBody = jsonBody;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            String ep = req.getEndpoint();
            if (ep != null && ep.contains('contact_staff_update_msg')) {
                res.setBody('{"ok":true}');
                return res;
            }
            if (ep != null && ep.contains('get_staff_data')) {
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