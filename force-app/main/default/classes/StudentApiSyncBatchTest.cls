@IsTest
private class StudentApiSyncBatchTest {

    @IsTest
    static void batch_upsertsStudent_fromApiPayload() {
        String uniqueStudentId = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        Map<String, Object> apiBody = new Map<String, Object>{
            'statusCode' => 200,
            'records' => new List<Object>{
                new Map<String, Object>{
                    'Student_ID__c' => uniqueStudentId,
                    'First_Name__c' => 'TestFirst',
                    'Last_Name__c' => 'TestLast',
                    'DBN__c' => '28Q505',
                    'Clean_Update__c' => '2026-06-29',
                    'DOB_RESI__c' => '20110203'
                }
            },
            'lastFetchedOsisId' => Integer.valueOf(uniqueStudentId)
        };

        Test.setMock(HttpCalloutMock.class, new StudentApiMock(JSON.serialize(apiBody)));
        Test.startTest();
        Database.executeBatch(new StudentApiSyncBatch(0), 1);
        Test.stopTest();

        List<Student__c> found = [
            SELECT Id, Student_ID__c, First_Name__c
            FROM Student__c
            WHERE Student_ID__c = :uniqueStudentId
            LIMIT 1
        ];
        System.assertEquals(1, found.size(), 'Student should be upserted by Student_ID__c');
        System.assertEquals('TestFirst', found[0].First_Name__c);
    }

    @IsTest
    static void preserveManualTeacherFor27Q475() {
        Test.setMock(HttpCalloutMock.class, new StudentApiMock('{}'));
        SyncGate.bypassSFSync = true;
        try {
            insert new Student__c(
                Student_ID__c = '999888777',
                DBN__c = '27Q475',
                Teacher__c = 'TWilliams12@schools.nyc.gov'
            );
        } finally {
            SyncGate.bypassSFSync = false;
        }

        List<Object> apiRecords = new List<Object>{
            new Map<String, Object>{
                'Student_ID__c' => '999888777',
                'DBN__c' => '27Q475',
                'Teacher__c' => 'John Smith',
                'First_Name__c' => 'Updated'
            }
        };

        StudentApiSyncBatch.preserveManualTeacherValues(apiRecords);

        Map<String, Object> result = (Map<String, Object>) apiRecords[0];
        System.assertEquals('TWilliams12@schools.nyc.gov', result.get('Teacher__c'));
        System.assertEquals('Updated', result.get('First_Name__c'));
    }

    @IsTest
    static void coerceForField_isoAndYyyymmddDate() {
        Schema.DescribeFieldResult dateF = Student__c.Clean_Update__c.getDescribe();
        Object iso = StudentApiSyncBatch.coerceForField('2026-06-29', dateF);
        System.assertNotEquals(null, iso, 'ISO date should parse');

        if (dateF.getType() == Schema.DisplayType.Date) {
            Object compact = StudentApiSyncBatch.coerceForField('20110203', dateF);
            System.assertEquals(Date.newInstance(2011, 2, 3), compact);
        }
    }

    private class StudentApiMock implements HttpCalloutMock {
        private final String studentJsonBody;

        StudentApiMock(String studentJsonBody) {
            this.studentJsonBody = studentJsonBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            String ep = req.getEndpoint();
            if (ep != null && ep.contains('nyc-doe-students')) {
                res.setBody(studentJsonBody);
                return res;
            }
            if (ep != null && ep.contains('hooks.slack.com')) {
                res.setBody('ok');
                return res;
            }
            res.setBody('{}');
            return res;
        }
    }
}