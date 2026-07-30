@IsTest
private class StaffContactApiSyncBatchTest {

    @IsTest
    static void staffBatch_upsertsContact_fromApiPayload() {
        String uniqueEmail = 'staff.batch.' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@schools.nyc.gov';
        Map<String, Object> apiBody = new Map<String, Object>{
            'body' => new List<Object>{
                new Map<String, Object>{
                    'FirstName' => 'TestFirst',
                    'LastName' => 'TestLast',
                    'Email' => uniqueEmail,
                    'DOE_API_Update__c' => 'True'
                }
            },
            'lastFetchedOsisId' => 1
        };

        Test.setMock(HttpCalloutMock.class, new StaffApiMock(JSON.serialize(apiBody), true));
        Test.startTest();
        Database.executeBatch(new StaffContactApiSyncBatch(0, StaffContactApiSyncBatch.SyncMode.STAFF), 1);
        Test.stopTest();

        List<Contact> found = [SELECT Id, Teacher_Email__c, FirstName FROM Contact WHERE Teacher_Email__c = :uniqueEmail LIMIT 1];
        System.assertEquals(1, found.size(), 'Contact should be upserted by Teacher_Email__c');
        System.assertEquals('TestFirst', found[0].FirstName);
    }

    @IsTest
    static void principalBatch_upsertsContact_fromApiPayload() {
        String uniqueEmail = 'principal.batch.' + String.valueOf(Math.abs(Crypto.getRandomInteger())) + '@schools.nyc.gov';
        Map<String, Object> apiBody = new Map<String, Object>{
            'body' => new List<Object>{
                new Map<String, Object>{
                    'FirstName' => 'PFirst',
                    'LastName' => 'PLast',
                    'Teacher_Email__c' => uniqueEmail,
                    'DOE_API_Update__c' => 'true'
                }
            },
            'lastFetchedOsisId' => 2
        };

        Test.setMock(HttpCalloutMock.class, new StaffApiMock(JSON.serialize(apiBody), false));
        Test.startTest();
        Database.executeBatch(new StaffContactApiSyncBatch(0, StaffContactApiSyncBatch.SyncMode.PRINCIPAL), 1);
        Test.stopTest();

        List<Contact> found = [SELECT Id FROM Contact WHERE Teacher_Email__c = :uniqueEmail LIMIT 1];
        System.assertEquals(1, found.size());
    }

    @IsTest
    static void coerceForField_booleanAndDate() {
        Schema.DescribeFieldResult boolF = Contact.HasOptedOutOfEmail.getDescribe();
        System.assertEquals(true, StaffContactApiSyncBatch.coerceForField('True', boolF));

        Schema.DescribeFieldResult dateF = Contact.Birthdate.getDescribe();
        Object d = StaffContactApiSyncBatch.coerceForField('1972-07-12', dateF);
        System.assertNotEquals(null, d);
    }

    private class StaffApiMock implements HttpCalloutMock {
        private final String staffJsonBody;
        private final Boolean includeSlack;

        StaffApiMock(String staffJsonBody, Boolean includeSlack) {
            this.staffJsonBody = staffJsonBody;
            this.includeSlack = includeSlack;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            String ep = req.getEndpoint();
            if (includeSlack && ep != null && ep.contains('contact_staff_update_msg')) {
                res.setBody('{"ok":true}');
                return res;
            }
            if (ep != null && (ep.contains('get_staff_data') || ep.contains('get_staff_data_principal'))) {
                res.setBody(staffJsonBody);
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