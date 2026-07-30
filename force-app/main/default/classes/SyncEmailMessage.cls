// Ankur's Code 
global class SyncEmailMessage implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
   
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        
        String query = 'SELECT Id, CreatedDate, RelationAddress, RelationId, RelationObjectType, RelationType, EmailMessage.Id, EmailMessage.ActivityId, EmailMessage.CcAddress, EmailMessage.CreatedDate, EmailMessage.ReplyToEmailMessageId, EmailMessage.Name, EmailMessage.EmailTemplateId, EmailMessage.ValidatedFromAddress, EmailMessage.FromAddress, EmailMessage.FromName, EmailMessage.HasAttachment, EmailMessage.HtmlBody, EmailMessage.RelatedToId, EmailMessage.Subject, EmailMessage.ToAddress FROM EmailMessageRelation WHERE CreatedDate > 2023-10-01T00:00:00.000Z';
        system.debug('query' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> Scope) {
        List<MyCustomObject> customObjectList = new List<MyCustomObject>();
        
        for (SObject record : Scope) {
            EmailMessageRelation emailMessage = (EmailMessageRelation)record;
            
            // Map other fields to the corresponding fields in MyCustomObject
            
            MyCustomObject customObject = new MyCustomObject();
            customObject.Id = emailMessage.Id;
            customObject.CreatedDate = emailMessage.CreatedDate;
            customObject.RelationAddress = emailMessage.RelationAddress;            
            customObject.RelationId = emailMessage.RelationId;
            customObject.RelationObjectType = emailMessage.RelationObjectType;
            customObject.RelationType = emailMessage.RelationType;
            customObject.EmailMessageId = emailMessage.EmailMessage.Id;
            customObject.ActivityId = emailMessage.EmailMessage.ActivityId; // Map ActivityId field
            customObject.CcAddress = emailMessage.EmailMessage.CcAddress;
            customObject.ReplyToEmailMessageId = emailMessage.EmailMessage.ReplyToEmailMessageId;
            customObject.Name = emailMessage.EmailMessage.Name;
            customObject.FromAddress = emailMessage.EmailMessage.FromAddress;
            customObject.FromName = emailMessage.EmailMessage.FromName;
            customObject.HasAttachment = emailMessage.EmailMessage.HasAttachment;
            customObject.HtmlBody = emailMessage.EmailMessage.HtmlBody;
            customObject.RelatedToId = emailMessage.EmailMessage.RelatedToId;
            customObject.Subject = emailMessage.EmailMessage.Subject;
            customObject.ToAddress = emailMessage.EmailMessage.ToAddress;
            
            // Retrieve Attachments for the EmailMessage
            List<Attachment> attachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :customObject.EmailMessageId];
            system.debug('attachments' + attachments);
            
            // Process Attachments
            for (Attachment attachment : attachments) {
               // system.JSONGenerator js = JSON.createGenerator(true);
              //  js.writeStartObject();
              //  js.writeBlobField('', attachment.Body);
                
             //   blob b = attachment.body;
              //  customObject.Attachment_URL = EncodingUtil.base64Encode(attachment.Body);
                 customObject.Attachment_Name = attachment.Name;
            }
            
            customObjectList.add(customObject);
        }
        
        String jsonData = JSON.serialize(customObjectList);
        system.debug('jsonData'+jsonData);
        
        Http http = new Http(); 
        HttpRequest req = new HttpRequest(); 
        req.setTimeout(60000);
        req.setMethod('POST');
     //   req.setBody(jsonData); 
      //  req.setEndpoint('https://ny67869sad.execute-api.us-east-2.amazonaws.com/production/syncDataInsights'); 
        req.setHeader('content-type', 'application/json;charset=UTF-8'); 
        req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER'); 
        HTTPResponse res = http.send(req); 
        if (res.getStatusCode() != 200) { 
            System.debug('The status code returned was not expected: ' + res.getStatusCode() + ' ' + res.getStatus()); 
          
        } else { 
            System.debug('last response'); 
            System.debug(res.getBody()); 
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations
    }
    
    // Define a custom object to hold the data you want to send to the API
    public class MyCustomObject {
        public String Id;
        public Datetime CreatedDate;
        public String RelationAddress;
        public String RelationId;
        public String RelationObjectType;
        public String RelationType;
        public String ActivityId; 
        public String CcAddress;
        public String ReplyToEmailMessageId;
        public String Name;
        public String FromAddress;
        public String FromName;
        public Boolean HasAttachment;
        public String HtmlBody;
        public String RelatedToId;
        public String Subject;
        public String ToAddress;
        public String EmailMessageId;
        public String Attachment_URL;
        public String Attachment_Name;
        // Add more fields as needed to match the API data structure
    }
}

// ANkur Code updated for testing with different purpose 
/*global class SyncEmailMessage implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        String query = 'SELECT Id, CreatedDate, RelationAddress, RelationId, RelationObjectType, RelationType, EmailMessage.Id, EmailMessage.ActivityId, EmailMessage.CcAddress, EmailMessage.CreatedDate, EmailMessage.ReplyToEmailMessageId, EmailMessage.Name, EmailMessage.EmailTemplateId, EmailMessage.ValidatedFromAddress, EmailMessage.FromAddress, EmailMessage.FromName, EmailMessage.HasAttachment, EmailMessage.HtmlBody, EmailMessage.RelatedToId, EmailMessage.Subject, EmailMessage.ToAddress FROM EmailMessageRelation where CreatedDate >= 2023-10-01T00:00:00.000+0000 AND CreatedDate <= 2023-10-18T00:00:00.000+0000';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> Scope) {
        List<MyCustomObject> customObjectList = new List<MyCustomObject>();
        
        for (SObject record : Scope) {
            EmailMessageRelation emailMessage = (EmailMessageRelation)record;
            
            // Map other fields to the corresponding fields in MyCustomObject
            MyCustomObject customObject = new MyCustomObject();
            customObject.Id = emailMessage.Id;
            customObject.CreatedDate = emailMessage.CreatedDate;
            customObject.RelationAddress = emailMessage.RelationAddress;
            customObject.RelationId = emailMessage.RelationId;
            customObject.RelationObjectType = emailMessage.RelationObjectType;
            customObject.RelationType = emailMessage.RelationType;
            customObject.EmailMessageId = emailMessage.EmailMessage.Id;
            customObject.ActivityId = emailMessage.EmailMessage.ActivityId;
            customObject.CcAddress = emailMessage.EmailMessage.CcAddress;
            customObject.ReplyToEmailMessageId = emailMessage.EmailMessage.ReplyToEmailMessageId;
            customObject.Name = emailMessage.EmailMessage.Name;
            customObject.FromAddress = emailMessage.EmailMessage.FromAddress;
            customObject.FromName = emailMessage.EmailMessage.FromName;
            customObject.HasAttachment = emailMessage.EmailMessage.HasAttachment;
            customObject.HtmlBody = emailMessage.EmailMessage.HtmlBody;
            customObject.RelatedToId = emailMessage.EmailMessage.RelatedToId;
            customObject.Subject = emailMessage.EmailMessage.Subject;
            customObject.ToAddress = emailMessage.EmailMessage.ToAddress;
            
            // Retrieve Attachments for the EmailMessage
            List<Attachment> attachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :customObject.EmailMessageId];
            
            // Process Attachments
            for (Attachment attachment : attachments) {
                system.JSONGenerator js = JSON.createGenerator(true);
                js.writeStartObject();
                js.writeBlobField('', attachment.Body);
                
                //   blob b = attachment.body;
                customObject.Attachment_URL = EncodingUtil.base64Encode(attachment.Body);
                customObject.Attachment_Name = attachment.Name;
            }
            
            customObjectList.add(customObject);
        }
        
        // Call the API
        callAPI(customObjectList);
    }
    
    // Function to call the API
    public void callAPI(List<MyCustomObject> customObjectList) {
        String jsonData = JSON.serialize(customObjectList);
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setTimeout(60000);
        req.setMethod('POST');
        req.setBody(jsonData);
        req.setEndpoint('https://ny67869sad.execute-api.us-east-2.amazonaws.com/production/syncDataInsights');
        req.setHeader('content-type', 'application/json;charset=UTF-8');
        req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' + res.getStatusCode() + ' ' + res.getStatus());
        } else {
            System.debug('API Response: ' + res.getBody());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Your finish logic here
    }
    
    // Define a custom object to hold the data you want to send to the API
    public class MyCustomObject {
        public String Id;
        public Datetime CreatedDate;
        public String RelationAddress;
        public String RelationId;
        public String RelationObjectType;
        public String RelationType;
        public String ActivityId;
        public String CcAddress;
        public String ReplyToEmailMessageId;
        public String Name;
        public String FromAddress;
        public String FromName;
        public Boolean HasAttachment;
        public String HtmlBody;
        public String RelatedToId;
        public String Subject;
        public String ToAddress;
        public String EmailMessageId;
        public String Attachment_URL;
        public String Attachment_Name;
        
        // Add more fields as needed to match the API data structure
    }
}*/




// Shan's Code Heap size issue solved but data is not going all
/*global class SyncEmailMessage implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
Integer batchSize = 50; // Set the batch size to 1 to send one record at a time
Integer recordsProcessed = 0; // To keep track of records processed

global Database.QueryLocator start(Database.BatchableContext BC) {
// collect the batches of records or objects to be passed to execute
String query = 'SELECT Id, CreatedDate, RelationAddress, RelationId, RelationObjectType, RelationType, EmailMessage.Id, EmailMessage.ActivityId, EmailMessage.CcAddress, EmailMessage.CreatedDate, EmailMessage.ReplyToEmailMessageId, EmailMessage.Name, EmailMessage.EmailTemplateId, EmailMessage.ValidatedFromAddress, EmailMessage.FromAddress, EmailMessage.FromName, EmailMessage.HasAttachment, EmailMessage.HtmlBody, EmailMessage.RelatedToId, EmailMessage.Subject, EmailMessage.ToAddress FROM EmailMessageRelation  where CreatedDate >= 2023-10-01T00:00:00.000+0000 AND CreatedDate <= 2023-10-18T00:00:00.000+0000 ORDER BY EmailMessage.Id';
system.debug('query' + query);
return Database.getQueryLocator(query);
}

global void execute(Database.BatchableContext BC, List<sObject> Scope) {
system.debug('Scope size'+Scope.size());
List<MyCustomObject> customObjectList = new List<MyCustomObject>();
system.debug('customObjectList size'+customObjectList.size());
// Ensure we don't exceed the batch size
for (Integer i = 0; i < batchSize && recordsProcessed < Scope.size(); i++) {
EmailMessageRelation emailMessage = (EmailMessageRelation)Scope[recordsProcessed];

// Map other fields to the corresponding fields in MyCustomObject
MyCustomObject customObject = new MyCustomObject();
customObject.Id = emailMessage.Id;
customObject.CreatedDate = emailMessage.CreatedDate;
customObject.RelationAddress = emailMessage.RelationAddress;            
customObject.RelationId = emailMessage.RelationId;
customObject.RelationObjectType = emailMessage.RelationObjectType;
customObject.RelationType = emailMessage.RelationType;
customObject.EmailMessageId = emailMessage.EmailMessage.Id;
customObject.ActivityId = emailMessage.EmailMessage.ActivityId; // Map ActivityId field
customObject.CcAddress = emailMessage.EmailMessage.CcAddress;
customObject.ReplyToEmailMessageId = emailMessage.EmailMessage.ReplyToEmailMessageId;
customObject.Name = emailMessage.EmailMessage.Name;
customObject.FromAddress = emailMessage.EmailMessage.FromAddress;
customObject.FromName = emailMessage.EmailMessage.FromName;
customObject.HasAttachment = emailMessage.EmailMessage.HasAttachment;
customObject.HtmlBody = emailMessage.EmailMessage.HtmlBody;
customObject.RelatedToId = emailMessage.EmailMessage.RelatedToId;
customObject.Subject = emailMessage.EmailMessage.Subject;
customObject.ToAddress = emailMessage.EmailMessage.ToAddress;

// Retrieve Attachments for the EmailMessage
List<Attachment> attachments = [SELECT Id, Name, Body FROM Attachment WHERE ParentId = :customObject.EmailMessageId];
system.debug('attachments' +attachments);
system.debug('attachments size' + attachments.size());

// Process Attachments
for (Attachment attachment : attachments) {
system.JSONGenerator js = JSON.createGenerator(true);
js.writeStartObject();
js.writeBlobField('', attachment.Body);
customObject.Attachment_URL = EncodingUtil.base64Encode(attachment.body);
customObject.Attachment_Name = attachment.Name;
}

customObjectList.add(customObject);
recordsProcessed++; // Increment recordsProcessed to move to the next record
}

String jsonData = JSON.serialize(customObjectList);
system.debug('jsonData'+jsonData);
system.debug('jsonData size'+ jsonData.length());

Http http = new Http(); 
HttpRequest req = new HttpRequest(); 
req.setTimeout(60000);
req.setMethod('POST');
req.setBody(jsonData); 
req.setEndpoint('https://ny67869sad.execute-api.us-east-2.amazonaws.com/production/syncDataInsights'); 
req.setHeader('content-type', 'application/json;charset=UTF-8'); 
req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER'); 
HTTPResponse res = http.send(req); 
if (res.getStatusCode() != 200) { 
System.debug('The status code returned was not expected: ' + res.getStatusCode() + ' ' + res.getStatus()); 
} else { 
System.debug('last response'); 
System.debug(res.getBody()); 
}
}   

global void finish(Database.BatchableContext BC) {
}

// Define a custom object to hold the data you want to send to the API
public class MyCustomObject {
public String Id;
public Datetime CreatedDate;
public String RelationAddress;
public String RelationId;
public String RelationObjectType;
public String RelationType;
public String ActivityId; 
public String CcAddress;
public String ReplyToEmailMessageId;
public String Name;
public String FromAddress;
public String FromName;
public Boolean HasAttachment;
public String HtmlBody;
public String RelatedToId;
public String Subject;
public String ToAddress;
public String EmailMessageId;
public String Attachment_URL;
public String Attachment_Name;
// Add more fields as needed to match the API data structure
}
}*/


// Other way to try this but not get result 
/*global class SyncEmailMessage implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
Integer batchSize = 200; // Set the batch size to 200 or adjust as needed
Integer recordsProcessed = 0;
List<MyCustomObject> customObjectList = new List<MyCustomObject>();

global Database.QueryLocator start(Database.BatchableContext BC) {
String query = 'SELECT Id, CreatedDate, RelationAddress, RelationId, RelationObjectType, RelationType, EmailMessage.Id, EmailMessage.ActivityId, EmailMessage.CcAddress, EmailMessage.CreatedDate, EmailMessage.ReplyToEmailMessageId, EmailMessage.Name, EmailMessage.EmailTemplateId, EmailMessage.ValidatedFromAddress, EmailMessage.FromAddress, EmailMessage.FromName, EmailMessage.HasAttachment, EmailMessage.HtmlBody, EmailMessage.RelatedToId, EmailMessage.Subject, EmailMessage.ToAddress FROM EmailMessageRelation WHERE CreatedDate >= 2023-10-01T00:00:00.000+0000 AND CreatedDate <= 2023-10-18T00:00:00.000+0000 ORDER BY EmailMessage.Id';
system.debug('query' + query);
return Database.getQueryLocator(query);
}

global void execute(Database.BatchableContext BC, List<sObject> Scope) {
for (Integer i = 0; i < Scope.size(); i++) {
EmailMessageRelation emailMessage = (EmailMessageRelation)Scope[i];
MyCustomObject customObject = new MyCustomObject();

customObject.Id = emailMessage.Id;
customObject.CreatedDate = emailMessage.CreatedDate;
customObject.RelationAddress = emailMessage.RelationAddress;
customObject.RelationId = emailMessage.RelationId;
customObject.RelationObjectType = emailMessage.RelationObjectType;
customObject.RelationType = emailMessage.RelationType;
customObject.EmailMessageId = emailMessage.EmailMessage.Id;
customObject.ActivityId = emailMessage.EmailMessage.ActivityId;
customObject.CcAddress = emailMessage.EmailMessage.CcAddress;
customObject.ReplyToEmailMessageId = emailMessage.EmailMessage.ReplyToEmailMessageId;
customObject.Name = emailMessage.EmailMessage.Name;
customObject.FromAddress = emailMessage.EmailMessage.FromAddress;
customObject.FromName = emailMessage.EmailMessage.FromName;
customObject.HasAttachment = emailMessage.EmailMessage.HasAttachment;
customObject.HtmlBody = emailMessage.EmailMessage.HtmlBody;
customObject.RelatedToId = emailMessage.EmailMessage.RelatedToId;
customObject.Subject = emailMessage.EmailMessage.Subject;
customObject.ToAddress = emailMessage.EmailMessage.ToAddress;

// Process Attachments for the EmailMessage
customObject.Attachment_URL = ''; // Initialize to an empty string
customObject.Attachment_Name = ''; // Initialize to an empty string

// Add code to handle attachments here

customObjectList.add(customObject);
recordsProcessed++;

if (customObjectList.size() == batchSize) {
sendToAPI(customObjectList);
customObjectList.clear();
}
}
}

global void finish(Database.BatchableContext BC) {
// If there are any remaining records in customObjectList, send them to the API
if (!customObjectList.isEmpty()) {
sendToAPI(customObjectList);
}
}

private void sendToAPI(List<MyCustomObject> data) {
String jsonData = JSON.serialize(data);

Http http = new Http();
HttpRequest req = new HttpRequest();
req.setTimeout(60000);
req.setMethod('POST');
req.setBody(jsonData);
req.setEndpoint('https://ny67869sad.execute-api.us-east-2.amazonaws.com/production/syncDataInsights');
req.setHeader('content-type', 'application/json;charset=UTF-8');
req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');

try {
HTTPResponse res = http.send(req);

if (res.getStatusCode() != 200) {
System.debug('The status code returned was not expected: ' + res.getStatusCode() + ' ' + res.getStatus());
} else {
System.debug('Last response');
System.debug(res.getBody());
}
} catch (Exception e) {
// Handle the exception, log the error, and continue processing
System.debug('An error occurred while sending the data: ' + e.getMessage());
}
}

public class MyCustomObject {
public String Id;
public Datetime CreatedDate;
public String RelationAddress;
public String RelationId;
public String RelationObjectType;
public String RelationType;
public String ActivityId;
public String CcAddress;
public String ReplyToEmailMessageId;
public String Name;
public String FromAddress;
public String FromName;
public Boolean HasAttachment;
public String HtmlBody;
public String RelatedToId;
public String Subject;
public String ToAddress;
public String EmailMessageId;
public String Attachment_URL;
public String Attachment_Name;
// Add more fields as needed to match the API data structure
}
}*/