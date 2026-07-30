@isTest
public class ChatlioEmailProcessingHandlerTest {
    @isTest
    static void testHandleInboundEmailWithValidEmail() {
        // Create a mock email
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.subject = 'Test Email';
        email.plainTextBody = 'Email: validemail@example.com';
        email.htmlBody = '<p>Email: validemail@example.com</p>';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        // Create an instance of the email handler
        ChatlioEmailProcessingHandler handler = new ChatlioEmailProcessingHandler();
        
        // Call the email handler
     
        handler.handleInboundEmail(email, envelope);
   
        
        // Verify that the Chatbot_Request__c record was created
        Chatbot_Request__c[] requests = [SELECT Email__c, CTLE_Request__c FROM Chatbot_Request__c WHERE Email__c = 'validemail@example.com'];
        System.assertEquals(1, requests.size());
        System.assertEquals('validemail@example.com', requests[0].Email__c);
        System.assertEquals(true, requests[0].CTLE_Request__c);
    }
    
    @isTest
    static void testHandleInboundEmailWithNoEmail() {
        // Create a mock email with no valid email address
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.fromAddress = 'test@example.com';
        email.subject = 'Test Email';
        email.plainTextBody = 'No valid email address here';
        email.htmlBody = '<p>No valid email address here</p>';
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        // Create an instance of the email handler
        ChatlioEmailProcessingHandler handler = new ChatlioEmailProcessingHandler();
        
        // Call the email handler
     
        handler.handleInboundEmail(email, envelope);

        
        // Verify that no Chatbot_Request__c records were created
        Chatbot_Request__c[] requests = [SELECT Email__c, CTLE_Request__c FROM Chatbot_Request__c];
        System.assertEquals(0, requests.size());
    }
}