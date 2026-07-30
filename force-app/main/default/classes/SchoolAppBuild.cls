global class SchoolAppBuild {
    @InvocableMethod(label = 'triggerSchoolAppBuild')
    //public static List < iOS_and_Android_App_Details__c > triggerSchoolAppBuild(List < iOS_and_Android_App_Details__c > schoolAppDetail){ 
    public static void triggerSchoolAppBuild(List < iOS_and_Android_App_Details__c > schoolAppDetail){
        String emailBody ='';   
        
        System.debug('Start WF:  '+ schoolAppDetail);
        System.debug('App Name: ' + schoolAppDetail[0].Name);
        System.debug('App Id:' + schoolAppDetail[0].Id);
        System.debug('Android App Build Status: ' + schoolAppDetail[0].Android_App_Build_Flow__c);
        System.debug('iOS App Build Status: ' + schoolAppDetail[0].iOS_App_Build_Flow__c);
        System.debug('schoolAppDetail Size------------' + schoolAppDetail.size());   
        
        for(Integer i =0; i < schoolAppDetail.size(); i++ ){
            emailBody =''+emailBody+'<br>'+'<br>'+schoolAppDetail[i].School_Name__c+'<br>'+schoolAppDetail[i].Id;
            
            // Adnroid Build Triggers
            if ( schoolAppDetail[i].Android_App_Build_Flow__c == 'Build'){
                System.debug('App Build Status 1: ' + schoolAppDetail[i].Android_App_Build_Flow__c);            
                doAreaCalloutAndroidBuildAsync(schoolAppDetail[i].Id);
            }  if ( schoolAppDetail[i].Android_App_Build_Flow__c == 'Update'){
                System.debug('App Build Status 2: ' + schoolAppDetail[i].Android_App_Build_Flow__c);            
                doAreaCalloutAsync(schoolAppDetail[i].Id);
            }  if ( schoolAppDetail[i].Android_App_Build_Flow__c == 'Test'){
                System.debug('App Build Status 3: ' + schoolAppDetail[i].Android_App_Build_Flow__c);            
                doAreaCalloutAndroidTestAsync(schoolAppDetail[i].Id);
            } if ( schoolAppDetail[i].Android_App_Build_Flow__c == 'Google_SSO_Verification'){
                System.debug('App Build Status 4: ' + schoolAppDetail[i].Android_App_Build_Flow__c);            
                doAreaCalloutAndroidGoogleSSOVerificationAsync(schoolAppDetail[i].Id);
            } 
            // End
            // iOS Build Triggers
            if ( schoolAppDetail[i].iOS_App_Build_Flow__c == 'Build'){
                System.debug('App Build Status 4: ' + schoolAppDetail[i].iOS_App_Build_Flow__c);            
                doAreaCalloutIOSAsync(schoolAppDetail[i].Id);
            }  if ( schoolAppDetail[i].iOS_App_Build_Flow__c == 'Update'){
                System.debug('App Build Status 5: ' + schoolAppDetail[i].iOS_App_Build_Flow__c);            
                doAreaCalloutIOSAsync(schoolAppDetail[i].Id);
            }  if ( schoolAppDetail[i].iOS_App_Build_Flow__c == 'Test'){
                System.debug('App Build Status 5: ' + schoolAppDetail[i].iOS_App_Build_Flow__c);            
                doAreaCalloutIOSAsync(schoolAppDetail[i].Id);
            }          
        } 
        //return schoolAppDetail; 
        sendEmail(emailBody);
    }
    
    //Send Email with the list of apps pushed to the store
    @future(callout=true)
    global static void sendEmail(String emailBody) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/sendsmtpEmail' );
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        String  Body = JSON.serialize(new Map<String, Object> {
            'from' => 'Tech Admin <techadmin@solvedconsulting.com>',
                'to' => 'techadmin@solvedconsulting.com',
                'subject' => 'App Pushed To Store',
                'html' => 'Hey, <br>One or more apps pushed to the stores using Jenkins. Please find the details below:'+'<b>'+emailBody+'<b>',   
                'text' => ' '});      
        // Parse the JSON response     
        request.setBody( Body);
        System.debug(Body);
        
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            System.debug(response.getStatusCode() + ' ' + response.getStatus());
            System.debug(response.getBody());
        }else {
            System.debug(response.getBody());
        }  
        //return response;  
    }
    
    @future(callout=true) 
    global static void doAreaCalloutAsync(String id) {        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
           
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        request.setTimeout(120000);
        request.setEndpoint('https://0nlnmwl4vg.execute-api.us-east-2.amazonaws.com/production/triggerJenkinsPipeline');
        request.setBody('{' + 
         '"platform" : "android",' +
         '"storeObjectId" : ' + id + ',' +
         '"buildType" : "update"' +
        '}');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        //System.debug(' HttpResponse response = http.send(request);' );
        // HTTP Request 
        HttpResponse response = http.send(request);
        
        // Parse the JSON response
        
        //System.debug('Gtting the response');
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus());
            System.debug(response.getBody());
        } else {
            System.debug(response.getBody());
        }
        //return response;
    }
    
    // Android Test
    
    @future(callout=true) 
    global static void doAreaCalloutAndroidTestAsync(String id) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();           
             
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');       
        request.setTimeout(120000);
        request.setEndpoint('https://0nlnmwl4vg.execute-api.us-east-2.amazonaws.com/production/triggerJenkinsPipeline');
        request.setBody('{' + 
         '"platform" : "android",' +
         '"storeObjectId" : ' + id + ',' +
         '"buildType" : "test"' +
        '}');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        System.debug(' HttpResponse response = http.send(request);' );
        // HTTP Request 
        HttpResponse response = http.send(request);
        
        // Parse the JSON response
        System.debug('Gtting the response');
        
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus());
            System.debug(response.getBody());
        } else {
            System.debug(response.getBody());
        }
    }
    //Android End
    
    //Android Build
    
    @future(callout=true) 
    global static void doAreaCalloutAndroidBuildAsync(String id) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
                     
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
               
        request.setTimeout(120000);
        request.setEndpoint('https://0nlnmwl4vg.execute-api.us-east-2.amazonaws.com/production/triggerJenkinsPipeline');
        request.setMethod('POST');
        request.setBody('{' + 
         '"platform" : "android",' +
         '"storeObjectId" : ' + id + ',' +
         '"buildType" : "build"' +
        '}');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        System.debug(' HttpResponse response = http.send(request);' );
        // HTTP Request 
        HttpResponse response = http.send(request);
        
        // Parse the JSON response
        
        System.debug('Gtting the response');
        
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus());
            System.debug(response.getBody());
        } else {
            System.debug(response.getBody());
        }
    }
    //Android Build End
    
    //Android Google SSO Verification
    
    @future(callout=true) 
    global static void doAreaCalloutAndroidGoogleSSOVerificationAsync(String id) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();           
             
        request.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');       
        request.setTimeout(120000);
        request.setEndpoint('https://0nlnmwl4vg.execute-api.us-east-2.amazonaws.com/production/triggerJenkinsPipeline');
        request.setBody('{' + 
         '"platform" : "android",' +
         '"storeObjectId" : ' + id + ',' +
         '"buildType" : "google_sso_verification"' +
        '}');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        System.debug(' HttpResponse response = http.send(request);' );
        // HTTP Request 
        HttpResponse response = http.send(request);
        
        // Parse the JSON response
        System.debug('Gtting the response');
        
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus());
            System.debug(response.getBody());
        } else {
            System.debug(response.getBody());
        }
    }
    
    //iOS Triggers
    @future(callout=true) 
    global static void doAreaCalloutIOSAsync(String id) {
        
        Http http = new Http();
        HttpRequest request2 = new HttpRequest();
        
        System.debug('Triggeringthe iOS build' );
            
        request2.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
        // timeout in milliseconds  
       
        request2.setTimeout(120000);
        request2.setEndpoint('https://0nlnmwl4vg.execute-api.us-east-2.amazonaws.com/production/triggerJenkinsPipeline');
        request2.setMethod('POST');
        request2.setBody('{' + 
         '"platform" : "ios",' +
         '"storeObjectId" : ' + id + ',' +
         '"buildType" : "update"' +
        '}');
        
        request2.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        System.debug(' HttpResponse response = http.send(request);' );
        // HTTP Request 
        HttpResponse response2 = http.send(request2);
        
        // Parse the JSON response      
        
        System.debug('Getting the response');
        if (response2.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response2.getStatusCode() + ' ' + response2.getStatus());
            System.debug(response2.getBody());
        } else {
            System.debug(response2.getBody());
        }
    }
}