@isTest
private class RAMSTestclass implements HttpCalloutMock
{
        static testmethod void test1()
        {
            Test.setMock(HttpCalloutMock.class, new RAMSTestclass());
            RAMS_Resource_Center__c sd = new RAMS_Resource_Center__c();
            sd.Contact_Name__c= 'Test';
            system.assertEquals('Test', sd.Contact_Name__c);
            
            Test.startTest();
            insert sd;
            update sd;
            delete sd;
            
            Test.stopTest();
        }
    
         public HttpResponse respond(HttpRequest req)
        {
            string fullJson = 'Your json response';
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    
}