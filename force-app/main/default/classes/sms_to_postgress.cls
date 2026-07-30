public class sms_to_postgress {
    
    public void sendRecordsToNodeJS() {
        // Calculate the date and time 24 hours ago
        DateTime twentyFourHoursAgo = System.now().addHours(-24);
        system.debug('twentyFourHoursAgo ' + twentyFourHoursAgo);
        // Query records from the tdc_tsw__Message__c object that haven't been sent yet
        List<tdc_tsw__Message__c> records = [SELECT Name, tdc_tsw__Delivered__c, tdc_tsw__Channel__c, tdc_tsw__Message_Text_New__c, tdc_tsw__Status__c, tdc_tsw__Error_Message__c,tdc_tsw__Created_Date__c
                                             FROM tdc_tsw__Message__c 
                                             WHERE  tdc_tsw__Created_Date__c >= :twentyFourHoursAgo ];
        
        system.debug('records ' + records);
        system.debug('recodsSize ' + records.size());
        
        // Make the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://qr6iymsb98.execute-api.us-east-2.amazonaws.com/dev/sendgrid/sms-history');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(records));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        // After successfully sending the records to Node.js
        if (res.getStatusCode() == 200) {
            System.debug('Request sent successfully to Node.js');
            System.debug('Response Body: ' + res.getBody());
            
        }
        else {
            System.debug('Error sending request to Node.js');
            System.debug('Status Code: ' + res.getStatusCode());
            System.debug('Response Body: ' + res.getBody());
        }
    }
}