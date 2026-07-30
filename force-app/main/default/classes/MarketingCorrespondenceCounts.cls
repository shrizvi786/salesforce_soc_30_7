//Used to sync plus apps activity logs count in Account and Contact objects
//
public class MarketingCorrespondenceCounts implements Database.Batchable<Object>, Database.AllowsCallouts, Database.Stateful {
    private Integer offset;
    public List<Account> accountResponse = new List<Account>();
    public List<Contact> contactResponse = new List<Contact>();
    
    public String currentObjectToSync; //used to check current object sync
    public Integer size; // to check the response list size
    public Boolean objName; 
    
    
    //Constructer For fetching lastFetchedOsisId
    public MarketingCorrespondenceCounts (Integer offset, String currentObjectToSync) {
        this.offset = offset;
        this.currentObjectToSync = currentObjectToSync;
    }        
    
    public  Iterable<Object> start(Database.BatchableContext context) {
        System.debug('offset' + offset);
        System.debug('currentObjectToSync' + currentObjectToSync);
        List<Object> accountIdsFromAPI;
        if(currentObjectToSync == 'Account'){
            accountIdsFromAPI = [select Id from Account LIMIT 10];
        }else{
            accountIdsFromAPI = [select Id from Contact LIMIT 10];
        }        
        return accountIdsFromAPI;
    }
    
    public void execute(Database.BatchableContext context, List<Object> scope) {
        System.debug('Inside execute method');
        size = callApi(currentObjectToSync); 
        System.debug('size:::: ' + size);
    }    
    
    public Integer callApi(String ObjectType) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(120000);       
        String endpointUrl = 'https://qr6iymsb98.execute-api.us-east-2.amazonaws.com/dev/sendgrid/get-counts-by-email?offset=' + offset + '&limit=' + 10;
        System.debug('Endpoint URL: ' + endpointUrl);
        request.setEndpoint(endpointUrl);
        request.setMethod('GET');
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        HttpResponse apiResponse = http.send(request);
        List<Object> apiResult;
        
        if (apiResponse.getStatusCode() == 200) {
            Map<String, Object> apiResponseMap = (Map<String, Object>) JSON.deserializeUntyped(apiResponse.getBody());
            System.debug('API Response Map: ' + apiResponseMap);
            apiResult = (List<Object>) apiResponseMap.get('body');
            
            if (!apiResult.isEmpty()) {
                if (currentObjectToSync == 'Contact') {
                    processContact(apiResult);                        
                }                                        
            }else{
                System.debug('No Logs to Sync in:::::' + currentObjectToSync);
            }                
        }else{
            System.debug('Api StatusCode not expected');
        }
        
        System.debug('ObjectDataList' + apiResult.size());
        return apiResult.size();
    }
    
    
    //Sync Plus Apps Logs in Contact object
    public void processContact(List<object> contactList) {
        contactResponse = new List<Contact>();
        System.debug('contactList::::::'+ contactList);
        
        for (Object contactDataObj : contactList) {
            Map<String, Object> contactData = (Map<String, Object>) contactDataObj;
            String externalContactId = (String) contactData.get('Recipient_Email');  // External Account ID from API
            System.debug('externalContactId' + externalContactId);
            Contact currentContactRecord;
            
            // Query for the matching Contact record in Salesforce
            try {
                currentContactRecord = [SELECT Id,Email FROM Contact WHERE Email = :externalContactId LIMIT 1];
                // Process the found Contact record here
            } catch (QueryException e) {
                // Handle the case when the Contact record is not found
                System.debug('Contact not found for externalContactId: ' + externalContactId);
            }
            
            if (currentContactRecord != null) {                
                // Update Contact fields based on the API data
                // Sendgrid mapping
                Map<String, Object> pbisData = (Map<String, Object>) contactData.get('sendGrid');
                currentContactRecord.Opens_Of_Sendgrid__c = Decimal.valueOf(String.valueOf(pbisData.get('Total_Number_Of_Opens')));
                currentContactRecord.Sends_Of_Sendgrid__c = Decimal.valueOf(String.valueOf(pbisData.get('Total_Number_Of_Sends')));
                
                
                // Mailchimp Mapping
                Map<String, Object> gradedData = (Map<String, Object>) contactData.get('Mailchimp');
                currentContactRecord.Opens_Of_Mailchimp__c = Decimal.valueOf(String.valueOf(gradedData.get('Total_Number_Of_Opens')));
                currentContactRecord.Sends_Of_Mailchimp__c	 = Decimal.valueOf(String.valueOf(gradedData.get('Total_Number_Of_Sends')));                    
                System.debug('gradedData' + gradedData);
                
                contactResponse.add(currentContactRecord);
                System.debug('contactresponseData' + contactResponse);
                System.debug('contactresponseData' + contactResponse.size());                                
            }         
        }  
        // Update logs count list to the Contact by id
        Database.UpsertResult[] results = Database.upsert(contactResponse, Contact.Fields.Id, false);
        System.debug('results::::::' + results);
    }
    
    public void finish(Database.BatchableContext context) {
        System.debug('Inside finish Method' + size);
        
        if (size == 0) {
            System.debug('size inside if' + size);
            offset = 0; 
            if(currentObjectToSync == 'Contact' && size == 0){
                System.debug('Data synced Successfully for Both Account and Contact');
            }
            else{
                MarketingCorrespondenceCounts log = new MarketingCorrespondenceCounts(offset, 'Contact');
                System.Database.executeBatch(log);  
            }            
        }
        else{
            System.debug('size inside else' + size);
            offset += 10;
            if (!Test.isRunningTest()) { // Check if not running a test
                MarketingCorrespondenceCounts log = new MarketingCorrespondenceCounts(offset, currentObjectToSync);
                System.Database.executeBatch(log);
            }
        }
    }
}