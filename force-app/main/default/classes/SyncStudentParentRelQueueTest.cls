@IsTest
private class SyncStudentParentRelQueueTest {

    private class QHttpMock implements HttpCalloutMock {
        private Integer callCount = 0;
        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            res.setStatusCode(200);

            if (callCount == 1 && req.getEndpoint().contains('limit=1&offset=0')) {
                res.setBody('{"totalCount":3,"body":[]}');
                return res;
            }

            String guardian;
            if (callCount == 2) guardian = '98765';
            else if (callCount == 3) guardian = '98766';
            else guardian = '98767';

            res.setBody(
                '{"totalCount":3,"body":['+
                    '{"Student__c":"12345","Student_Parent_Guardian__c":"'+guardian+'"}'+
                ']}'
            );
            return res;
        }
    }

    @IsTest
    static void testQueueable_kickoff_pageSize1_chunk3() {
        Test.setMock(HttpCalloutMock.class, new QHttpMock());

        insert new Student__c(Student_ID__c='12345');
        insert new Student_Parent_Guardian__c(phone_guardian__c='98765');
        insert new Student_Parent_Guardian__c(phone_guardian__c='98766');
        insert new Student_Parent_Guardian__c(phone_guardian__c='98767');

        Test.startTest();
            Id jobId = SyncStudentParentRelQueue.kickoff(1, 3);
        Test.stopTest();

        Integer cnt = [SELECT COUNT() FROM Student_Parent_Relationship__c];
        System.assertEquals(1, cnt, 'Expected 3 unique relationships');
    }
}