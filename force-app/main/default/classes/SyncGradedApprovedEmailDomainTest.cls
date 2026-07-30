@isTest
public class SyncGradedApprovedEmailDomainTest {
       private class Restmock implements HttpCalloutmock
       {
           public HTTPResponse respond(HTTPRequest req) {
             String fullJson = 'Your Json Response';
             HTTPResponse res=new HTTPResponse();
             res.setHeader('Content-Type', 'text/json');
             res.setBody(fullJson);
             res.setStatusCode(200);
             return res;
       }
    }
         Static testmethod void myTest()
         {
             Test.setMock(HttpCalloutMock.class, new RestMock());
             Test.startTest();
             Graded_Approved_Email_Domain__c primaryObject =new Graded_Approved_Email_Domain__c(Email_Domain__c = 'test@gmail.com');
             insert primaryObject;            
             update primaryObject;
             System.assertEquals('test@gmail.com', primaryObject.Email_Domain__c);    
             delete primaryObject;       
             Test.StopTest();           
          }
}