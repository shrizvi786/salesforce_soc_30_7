/**
 * Single test class for TriggerSFSyncAPI and related sync UI/batch entry points.
 * Composite HTTP mock covers Monday.com (when Account + DBN enqueue Sync_AccountMonday) and sync/AWS endpoints.
 */
@IsTest
public class TriggerSFSyncAPITest {

    private class CompositeSyncCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json;charset=UTF-8');

            String ep = req.getEndpoint() != null ? req.getEndpoint() : '';
            if (ep.contains('api.monday.com')) {
                String body = req.getBody() != null ? req.getBody() : '';
                if (body.contains('next_items_page')) {
                    res.setBody('{"data":{"next_items_page":{"cursor":null,"items":[]}}}');
                } else if (body.contains('items_page')) {
                    res.setBody('{"data":{"boards":[{"items_page":{"cursor":null,"items":[]}}]}}');
                } else if (body.contains('create_item')) {
                    res.setBody('{"data":{"create_item":{"id":"12345"}}}');
                } else if (body.contains('change_multiple_column_values')) {
                    res.setBody('{"data":{"change_multiple_column_values":{"id":"12345"}}}');
                } else if (body.contains('delete_item')) {
                    res.setBody('{"data":{"delete_item":{"id":"12345"}}}');
                } else {
                    res.setBody('{"data":{}}');
                }
                return res;
            }

            res.setBody('{"success":true,"message":"ok"}');
            return res;
        }
    }

    @IsTest
    static void testTriggerSFSyncAPI_InsertUpdateDelete() {
        Test.setMock(HttpCalloutMock.class, new CompositeSyncCalloutMock());

        Account acc = TestDataFactory.createAccount(201, 'TSYNC-ZZ2');

        String objectName = 'Account';
        List<String> serialized = new List<String>{ JSON.serialize(acc) };
        List<SObject> forUpdate = new List<SObject>{ acc };

        Test.startTest();
        System.enqueueJob(
            new TriggerSFSyncAPI(objectName, serialized, 'actionInsert', forUpdate)
        );
        System.enqueueJob(
            new TriggerSFSyncAPI(objectName, serialized, 'actionUpdate', forUpdate)
        );
        System.enqueueJob(
            new TriggerSFSyncAPI(
                objectName,
                new List<String>{ acc.Id },
                'actionDelete',
                new List<SObject>()
            )
        );
        Test.stopTest();
    }

    @IsTest
    static void testSyncButtonMobileApp_StudentBatch() {
        Test.setMock(HttpCalloutMock.class, new CompositeSyncCalloutMock());

        Student__c testRecord = new Student__c(
            First_Name__c = 'Test Record',
            Email__c = 'test@example.com'
        );
        insert testRecord;
        update testRecord;
        delete testRecord;

        PageReference testPageRef = Page.SyncButtonMobileApp;
        testPageRef.getParameters().put('objectApiName', 'Student__c');
        Test.setCurrentPage(testPageRef);

        Test.startTest();
        SyncButtonMobileApp.SyncButton();
        Test.stopTest();
    }

    @IsTest
    static void testBatchableExecution_SchoolApp() {
        Test.setMock(HttpCalloutMock.class, new CompositeSyncCalloutMock());

        Account acc = TestDataFactory.createAccount(1, 'DBN-SCHED-1');

        School_App__c testRecord = new School_App__c(
            School_Name__c = acc.Id,
            App_Logo__c = 'Test Logo',
            Primary_Color__c = '#FFFFFF',
            Splash_Screen__c = 'Test Splash Screen',
            Bottom_Navigation__c = 'Social_0xe821'
        );
        insert testRecord;

        Test.startTest();
        Database.executeBatch(new SyncButtonMobileAppRecord('School_App__c'), 50);
        Test.stopTest();

        List<School_App__c> records = [
            SELECT Id, School_Name__c, App_Logo__c, Primary_Color__c
            FROM School_App__c
        ];
        System.assertNotEquals(0, records.size(), 'School_App__c records should exist.');
    }
}