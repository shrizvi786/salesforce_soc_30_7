@isTest
public class SyncCalendarTest {
    
      private class Restmock implements HttpCalloutmock
      {
          public HTTPResponse respond (HTTPRequest req){
              String fullJson='Your Json Response';
              HTTPResponse res=new HTTPResponse();
              res.setHeader('Content-Type', 'text/json');
              res.setBody(fullJson);
              res.setStatusCode(200);
              return res;
              
          }
      }
        Static testmethod void myTest(){
            Test.setMock(HttpCalloutMock.class, new RestMock());
            Test.startTest();
            
            Calendar__c primaryObject = new Calendar__c(Month__c = 'Test Record'); 
            insert primaryObject;
            update primaryObject;
            System.assertEquals('Test Record', primaryObject.Month__c);    
            delete primaryObject;       
            Test.StopTest();     
        
    }
}