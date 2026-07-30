global class ChatlioEmailProcessingHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        // Log the email content
        System.debug('Received email from: ' + email.fromAddress);
        System.debug('Subject: ' + email.subject);
        System.debug('Plain Text Body: ' + email.plainTextBody);
        System.debug('HTML Body: ' + email.htmlBody);

        // Extract the email address from the plain text body
        String plainTextBody = email.plainTextBody;
        String emailAddress = extractEmail(plainTextBody);

        if (emailAddress != null) {
            // Create a new Chatbot_Request__c record
            Chatbot_Request__c chatbotRequest = new Chatbot_Request__c();
            chatbotRequest.Email__c = emailAddress;
            chatbotRequest.CTLE_Request__c = true;

            // Insert the record
            try {
                insert chatbotRequest;
                System.debug('Chatbot_Request__c record created with Email: ' + emailAddress);
            } catch (Exception e) {
                System.debug('Failed to create Chatbot_Request__c record: ' + e.getMessage());
            }
        } else {
            System.debug('No valid email address found in the plain text body.');
        }

        return result;
    }

    // Helper method to extract the email address from the plain text body
    private String extractEmail(String body) {
        // Regular expression to match email addresses
        Pattern emailPattern = Pattern.compile('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}');
        Matcher matcher = emailPattern.matcher(body);
        
        if (matcher.find()) {
            return matcher.group();
        } else {
            return null;
        }
    }
}

/*
global class ChatlioEmailProcessingHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        // Log the email content
        System.debug('Received email from: ' + email.fromAddress);
        System.debug('Subject: ' + email.subject);
        System.debug('Plain Text Body: ' + email.plainTextBody);
        System.debug('HTML Body: ' + email.htmlBody);

        // Your email processing logic goes here

        return result;
    }
}
*/