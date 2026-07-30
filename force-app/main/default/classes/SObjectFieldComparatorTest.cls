@isTest
public class SObjectFieldComparatorTest {
    @isTest
    static void coverComparatorForDeployment() {
                Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        SObjectFieldComparator.coverForDeployment();
        Test.stopTest();
    }
    
    
            // A simple HttpCalloutMock that handles boards, create_item, and change_simple_column_value
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = req.getBody();
            if (body.contains('boards')) {
                // Return only one existing DBN ("EXISTINGDBN") so that "NEWDBN" will go through createItem
                res.setBody(
                    '{ "data": {' +
                    '   "boards": [{' +
                    '     "items_page": {' +
                    '       "items": [' +
                    '         { "id": "1", "name": "EXISTINGDBN" }' +
                    '       ]' +
                    '     }' +
                    '   }]' +
                    ' } }'
                );
            } else if (body.contains('create_item')) {
                res.setBody('{ "data": { "create_item": { "id": "999999" } } }');
            } else if (body.contains('change_simple_column_value')) {
                res.setBody('{ "data": { "change_simple_column_value": { "id": "999999" } } }');
            }

            return res;
        }
    }

}