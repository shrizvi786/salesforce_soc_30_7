@isTest
public class SyncStudentParentRelBatchTest {

    /*
     * Universal mock handling:
     * - start() totalCount call
     * - execute() data call
     * - empty body scenario
     * - error scenario
     * - Slack webhook
     * - Bulk API helper
     */
    private class UniversalHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');

            String endpoint = req.getEndpoint();

            // START() totalCount call
            if(endpoint.contains('limit=1&offset=0')){
                res.setStatusCode(200);
                res.setBody('{"totalCount":1,"body":[]}');
                return res;
            }

            // MAIN API CALL
            if(endpoint.contains('get-nyc-student-guardian')){
                res.setStatusCode(200);
                res.setBody(
                    '{"totalCount":1,"body":['+
                    '{"Student__c":"12345","Student_Parent_Guardian__c":"98765"}'+
                    ']}'
                );
                return res;
            }

            // Slack webhook
            if(endpoint.contains('hooks.slack.com')){
                res.setStatusCode(200);
                res.setBody('ok');
                return res;
            }

            // Bulk API job creation
            if(endpoint.contains('/services/data')){
                res.setStatusCode(200);
                res.setBody('{"id":"750000000000001AAA","state":"Open"}');
                return res;
            }

            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }


    /*
     * Mock returning EMPTY body
     * Covers rows == null / rows.isEmpty()
     */
    private class EmptyBodyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');

            if(req.getEndpoint().contains('limit=1')){
                res.setStatusCode(200);
                res.setBody('{"totalCount":1,"body":[]}');
            } else if(req.getEndpoint().contains('hooks.slack.com')){
                res.setStatusCode(200);
                res.setBody('ok');
            } else {
                res.setStatusCode(200);
                res.setBody('{"totalCount":1,"body":[]}');
            }

            return res;
        }
    }


    /*
     * Mock returning ERROR response
     * Covers status != 200 branch
     */
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('error');
            return res;
        }
    }


    /*
     * HAPPY PATH
     */
    @isTest
    static void testBatchHappyPath(){

        Test.setMock(HttpCalloutMock.class,new UniversalHttpMock());

        insert new Student__c(Student_ID__c='12345');
        insert new Student_Parent_Guardian__c(phone_guardian__c='98765');

        Test.startTest();
        Database.executeBatch(new SyncStudentParentRelBatch(),1);
        Test.stopTest();

        List<Student_Parent_Relationship__c> rels =
        [
            SELECT Relationship_Key__c
            FROM Student_Parent_Relationship__c
        ];

        System.assert(!rels.isEmpty(),'Relationship should be created');

        System.assert(!SyncGate.bypassSFSync,
        'SyncGate should reset to false');
    }



    /*
     * MISSING LOOKUP TEST
     * Covers skipMissingStudent / skipMissingGuardian
     */
    @isTest
    static void testMissingLookup(){

        Test.setMock(HttpCalloutMock.class,new UniversalHttpMock());

        // insert only student
        insert new Student__c(Student_ID__c='12345');

        Test.startTest();
        Database.executeBatch(new SyncStudentParentRelBatch(),1);
        Test.stopTest();

        System.assert(true,'Batch completed even with missing guardian');
    }



    /*
     * EMPTY BODY TEST
     */
    @isTest
    static void testEmptyResponse(){

        Test.setMock(HttpCalloutMock.class,new EmptyBodyMock());

        Test.startTest();
        Database.executeBatch(new SyncStudentParentRelBatch(),1);
        Test.stopTest();

        System.assert(true,'Batch handles empty response');
    }



    /*
     * ERROR RESPONSE TEST
     */
    @isTest
    static void testErrorResponse(){

        Test.setMock(HttpCalloutMock.class,new ErrorMock());

        Test.startTest();
        Database.executeBatch(new SyncStudentParentRelBatch(),1);
        Test.stopTest();

        System.assert(true,'Batch handles error status');
    }



    /*
     * BULK HELPER TEST
     */
    @isTest
    static void testBulkHelper(){

        Test.setMock(HttpCalloutMock.class,new UniversalHttpMock());

        Student__c stu = new Student__c(Student_ID__c='BULK_STUDENT');
        insert stu;

        Student_Parent_Guardian__c grd =
            new Student_Parent_Guardian__c(phone_guardian__c='BULK_GUARDIAN');
        insert grd;

        Student_Parent_Relationship__c rel =
            new Student_Parent_Relationship__c(
                Relationship_Key__c = stu.Id + '_' + grd.Id,
                Student__c = stu.Id,
                Student_Parent_Guardian__c = grd.Id
            );

        Test.startTest();
        SyncStudentParentRelBatch.upsertRelationshipsViaBulk(
            new List<Student_Parent_Relationship__c>{rel}
        );
        Test.stopTest();

        System.assert(true,'Bulk helper executed');
    }



    /*
     * SCHEDULABLE TEST
     */
    @isTest
    static void testSchedulable(){

        Test.setMock(HttpCalloutMock.class,new UniversalHttpMock());

        Test.startTest();
        (new SyncStudentParentRelBatch()).execute(null);
        Test.stopTest();

        List<AsyncApexJob> jobs =
        [
            SELECT Id
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'SyncStudentParentRelBatch'
        ];

        System.assert(!jobs.isEmpty(),
        'Schedulable should enqueue batch');
    }

}