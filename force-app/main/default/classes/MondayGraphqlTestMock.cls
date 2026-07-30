@IsTest
public class MondayGraphqlTestMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        String body = req.getBody() != null ? req.getBody() : '';

        if (body.contains('columns(types: [subtasks])')) {
            res.setBody(
                '{"data":{"boards":[{"columns":[{"settings_str":"{\\"boardIds\\":[18410023656]}"}]}]}}'
            );
        } else if (body.contains('subitems')) {
            res.setBody(
                '{"data":{"items":[{"id":"item-1","name":"TESTDBN","subitems":[]}]}}'
            );
        } else if (body.contains('users')) {
            res.setBody('{"data":{"users":[{"id":1,"name":"Test User"}]}}');
        } else if (body.contains('items_page_by_column_values')) {
            res.setBody('{"data":{"items_page_by_column_values":{"items":[]}}}');
        } else if (body.contains('create_item')) {
            res.setBody('{"data":{"create_item":{"id":"new-item-id"}}}');
        } else if (body.contains('change_multiple_column_values') || body.contains('change_simple_column_value')) {
            res.setBody('{"data":{"change_multiple_column_values":{"id":"item-id"}}}');
        } else if (body.contains('boards')) {
            res.setBody('{"data":{"boards":[{"items_page":{"items":[]}}]}}');
        } else {
            res.setBody('{"data":{}}');
        }

        return res;
    }
}