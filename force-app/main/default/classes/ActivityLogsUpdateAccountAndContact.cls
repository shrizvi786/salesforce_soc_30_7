public class ActivityLogsUpdateAccountAndContact {
    public static Map<String, Object> body;
    public static Map<String, Object> pushBody;
    public static String idValue;
    public static String objName;
    public static String latestPushMessages;
    
    @RemoteAction
    public static void callOut(String idValue, String objName){
        
        system.debug('idValue: '+idValue);
        system.debug('objName: '+objName);
        
        if(objName == 'Contact'){
            //Getiing Email of current record
            List<Contact> con = [Select id, email from Contact where Id =: idValue];
            String email = con[0].email;  
            system.debug('email: '+email);
            
            //Calling API to get Activity Logs for contact object
            ActivityLogsUpdateAccountAndContact.SyncActivityLogsUpdateAccountAndContact ac = new ActivityLogsUpdateAccountAndContact.SyncActivityLogsUpdateAccountAndContact();
            body = ac.SyncActivityLogsUpdateAccountAndContact(idValue,email,'Contact');
            
            //Perform DML 
            updateLogs(objName, idValue);
        }else{       
            
            //Calling API to get Activity Logs
            ActivityLogsUpdateAccountAndContact.SyncActivityLogsUpdateAccountAndContact ac = new ActivityLogsUpdateAccountAndContact.SyncActivityLogsUpdateAccountAndContact();
            body = ac.SyncActivityLogsUpdateAccountAndContact(idValue,'','Account');
            
            //Calling API to get Push Logs
            pushBody = ac.SyncPushLogAccount(idValue,'','Account');   
            
            //Function to get Newest Push Message
            latestPushMessages = ac.updatePushMessage(idValue);
            
            //Perform DML 
            updateLogs(objName, idValue);
        }  
    }
    public class SyncActivityLogsUpdateAccountAndContact {
        
        public Map<String, Object> SyncActivityLogsUpdateAccountAndContact(String id, String email, String objName){
            system.debug('Inside SyncActivityLogsUpdateAccountAndContact');
            String requestBody;
            Map<String, Object> bodyMap = new Map<String, Object>();
            
            // Create the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/log-manager/app-plus-log-counts');
            req.setMethod('POST');
            req.setHeader('Content-Type','application/json;charset=UTF-8');
            req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
            req.setTimeout(120000); 
            
            if(objName == 'Contact'){
                requestBody = '{"activityTypes": "PBIS,STUDENT,GRADED", "email": "'+email+'", "account_Id": ""}';
            }
            else{
                requestBody = '{"activityTypes": "PBIS,STUDENT,GRADED", "email": "", "account_Id": "' + id + '"}'; 
            }
            
            req.setBody(requestBody);
            Http http = new Http();
            HttpResponse res;
            
            try {
                res = http.send(req);
                system.debug(res);
                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    bodyMap = (Map<String, Object>) responseMap.get('body');                                       
                } else {
                    System.debug('Request failed with status code: ' + res.getStatusCode());
                }
            } catch (Exception ex) {
                System.debug('Error occurred while making the request: ' + ex.getMessage());
            }  
            
            return bodyMap;
        } 
        
        public Map<String, Object> SyncPushLogAccount(String id, String email, String objName){            
            String requestBody;
            Map<String, Object> bodyMap = new Map<String, Object>();
            
            system.debug('id: '+id);
            system.debug('email: '+email);
            system.debug('objName: '+objName);
            
            // Create the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://wvl7o182d6.execute-api.us-east-2.amazonaws.com/production/v2/log-manager/push-analytics-counts');
            req.setMethod('POST');
            req.setHeader('Content-Type','application/json;charset=UTF-8');
            req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
            req.setTimeout(120000); 
            requestBody = '{"accountId": "' + id + '"}'; 
            req.setBody(requestBody);
            Http http = new Http();
            HttpResponse res;
            
            try {
                res = http.send(req);
                system.debug('SyncPushLogAccount' +res);
                
                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    bodyMap = (Map<String, Object>) responseMap.get('body');
                } else {
                    System.debug('Request failed with status code: ' + res.getStatusCode());
                }
            } catch (Exception ex) {
                System.debug('Error occurred while making the request: ' + ex.getMessage());
            }
            
            return bodyMap;
        }   
        
        public Id updatePushMessage(String id) {                       
            Id MessageId;
            Push_Message__c latestPushMessage;
            
            try{
                // Fetch the latest inserted record from Push_Messages__c
                latestPushMessage = [SELECT Id, Message_Title__c, Date_sent__c FROM Push_Message__c WHERE Account__c = :id ORDER BY Date_sent__c DESC LIMIT 1];
            }catch (QueryException e){
                System.debug('No records found for this Account' + id);
            }
            
            // Check if a record was found
            if (latestPushMessage != null) {
                MessageId = latestPushMessage.Id;
                system.debug('MessageId: ' + MessageId);
            } else {
                system.debug('No Push Message found for AccountId: ' + id);
            }
            
            return MessageId;
        }
    }   
    
    public static void updateLogs(String objName, String idValue) {
        // Access bodyMap and accountId here
        system.debug('Inside function: ' + body);
        system.debug('Body Size: ' + body.size());
        system.debug('Inside function: ' + pushBody);
        system.debug('Inside function objName: ' + objName);
        system.debug('Inside function idValue: ' + idValue);
        
        if(objName == 'Account'){
            Account acc = [SELECT Id, PBIS_Logins__c from Account Where Id = :idValue]; 
            //Update PBIS Activity Logs
            Map<String, Object> pbisMap = (Map<String, Object>) body.get('PBIS');
            Map<String, Object> gradedMap = (Map<String, Object>) body.get('GRADED');
            Map<String, Object> studentMap = (Map<String, Object>) body.get('STUDENT');
            Map<String, Object> dashboardMap = (Map<String, Object>) body.get('DASHBOARD');
            
            if(body.size() > 0){
                
                //Update PBIS Activity Logs
                acc.PBIS_Logins__c = (Integer) pbisMap.get('Total_Sessions');
                acc.PBIS_Total_points_awarded__c = (Integer) pbisMap.get('Total_Points_Awarded');
                acc.PBIS_Total_session_points_awarded__c = (Integer) pbisMap.get('Total_Session_Points_Awarded');
                Decimal avgSessionDurationDecimal = (Decimal)pbisMap.get('Avg_Session_Duration');
                acc.PBIS_Avg_session_duration__c = avgSessionDurationDecimal;
                
                //Update GRADED Activity Logs
                acc.GRADED_Logins__c = (Integer) gradedMap.get('Total_Sessions');
                acc.GRADED_Total_assignments__c = (Integer) gradedMap.get('Total_Assignments');
                acc.GRADED_Total_student_work_scans__c = (Integer) gradedMap.get('Total_Student_Work_Scans');
                Decimal avgSessionDuration = (Decimal)gradedMap.get('Avg_Session_Duration');
                acc.GRADED_Avg_Session_Duration__c = avgSessionDuration;
                
                //Update STUDENT Activity Logs
                acc.STUDENT_Login__c = String.valueOf(studentMap.get('Total_Sessions'));
                acc.STUDENT_Total_student_searches__c = (Integer) studentMap.get('Total_Student_Searches');
                Decimal avgSessions = (Decimal)studentMap.get('Avg_Session_Duration');
                acc.STUDENT_Avg_session_duration__c = avgSessions;
                
                //Update Dashboard Activity Logs
                acc.DASHBOARD_Logins__c = (Integer) dashboardMap.get('DASHBOARD_Logins__c');
                //lastDashboardLogin = (String) dashboardMap.get('DASHBOARD_Last_Login__c');
                acc.DASHBOARD_Total_Views__c = (Integer) dashboardMap.get('DASHBOARD_Total_Views__c');
                acc.DASHBOARD_Unique_Users__c = (Integer) dashboardMap.get('DASHBOARD_Unique_Users__c');
            }
            
            if(pushBody.size() > 0){
                //Udate Push Logs Counts 
                acc.Total_Pushes_Sent__c = (Integer) pushBody.get('Total_Pushes_Sent__c');
                acc.Total_Push_Messages_Sent__c = (Integer) pushBody.get('Total_Pushes_Sent__c');
                acc.Total_News_Interactions__c = (Integer) pushBody.get('Total_News_Interactions__c');
                acc.Total_Social_Interactions__c = (Integer) pushBody.get('Total_Social_Interactions__c');
                acc.Total_Subscribed_Users__c = (Integer) pushBody.get('Total_Subscribed_Users__c'); 
                Object lastPushDateObject = pushBody.get('Last_Push_Date');
                if (lastPushDateObject != '') {
                    String lastPushDateString = (String) lastPushDateObject;
                    try {
                        acc.Newest_Push_Date__c = Date.valueOf(lastPushDateString);
                    } catch (Exception e) {
                        // Handle the case when the date string is invalid
                        // For example, you might want to set a default date or log the error
                        System.debug('Error: Invalid date format for Last_Push_Date');
                    }
                }                
                //acc.Newest_Push_Date__c = Date.valueOf((String) pushBody.get('Last_Push_Date'));
                acc.Newest_Push_Messages__c = (String) pushBody.get('Newest_Push_Messages');
                acc.Newest_Push_Message__c = String.Valueof(latestPushMessages);
                acc.Total_Mini_Clip_Interactions__c = (Integer) pushBody.get('Total_Mini_Clip_Interactions__c');
                acc.Successful_Push_Deliveries_IOS__c = (Integer) pushBody.get('Successful_Push_Deliveries_IOS__c');
                acc.Successful_Push_Deliveries_Android__c = (Integer) pushBody.get('Successful_Push_Deliveries_Android__c');
            }
            System.debug('acc::::::' + acc);
            update acc;
            
        }else{
            
            Contact con = [SELECT Id, PBIS_Logins__c from Contact Where Id = :idValue]; 
             
            //Update PBIS Activity Logs
            Map<String, Object> pbisMap = (Map<String, Object>) body.get('PBIS');
            Map<String, Object> gradedMap = (Map<String, Object>) body.get('GRADED');
            Map<String, Object> studentMap = (Map<String, Object>) body.get('STUDENT');
            Map<String, Object> dashboardMap = (Map<String, Object>) body.get('DASHBOARD');
            
            if(body.size() > 0){
                
                //Update PBIS Activity Logs
                con.PBIS_Logins__c = (Integer) pbisMap.get('Total_Sessions');
                con.PBIS_Total_points_awarded__c = (Integer) pbisMap.get('Total_Points_Awarded');
                con.PBIS_Total_session_points_awarded__c = (Integer) pbisMap.get('Total_Session_Points_Awarded');
                Decimal avgSessionDurationDecimal = (Decimal)pbisMap.get('Avg_Session_Duration');
                con.PBIS_Avg_session_duration__c = avgSessionDurationDecimal;
                
                //Update GRADED Activity Logs
                con.GRADED_Logins__c = (Integer) gradedMap.get('Total_Sessions');
                con.GRADED_Total_assignments__c = (Integer) gradedMap.get('Total_Assignments');
                con.GRADED_Total_student_work_scans__c = (Integer) gradedMap.get('Total_Student_Work_Scans');
                Decimal avgSessionDuration = (Decimal)gradedMap.get('Avg_Session_Duration');
                con.GRADED_Avg_Session_Duration__c = avgSessionDuration;
                
                //Update STUDENT Activity Logs
                con.STUDENT_Login__c = (Integer) studentMap.get('Total_Sessions');
                con.STUDENT_Total_student_searches__c = (Integer) studentMap.get('Total_Student_Searches');
                Decimal avgSessions = (Decimal)studentMap.get('Avg_Session_Duration');
                con.STUDENT_Avg_session_duration__c = avgSessions;
                
                //Update Dashboard Activity Logs
                con.DASHBOARD_Logins__c = (Integer) dashboardMap.get('DASHBOARD_Logins__c');
                con.DASHBOARD_Last_Login__c = (String) dashboardMap.get('DASHBOARD_Last_Login__c');
                con.DASHBOARD_Total_Views__c = (Integer) dashboardMap.get('DASHBOARD_Total_Views__c');
            }
            System.debug('con::::::' + con);
            update con;
        }
    }
}