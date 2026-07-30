public class doe_not_updated_class {
    @future(callout=true)
    public static void send(List<Id> contactIds) {
        List<Contact> contacts = [SELECT Id, DOE_Not_Updated__c, Teacher_Email__c FROM Contact WHERE Id IN :contactIds];
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://wrrvbh0snl.execute-api.us-east-2.amazonaws.com/prod/doe_not_update');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        List<Map<String, Object>> payload = new List<Map<String, Object>>();
        for (Contact con : contacts) {
            Map<String, Object> contactData = new Map<String, Object>();
            contactData.put('DOE_Not_Updated', con.DOE_Not_Updated__c);
            contactData.put('Teacher_Email', con.Teacher_Email__c);
            payload.add(contactData);
        }
        
        req.setBody(JSON.serialize(payload));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        // You can handle the response here if needed
    }
}