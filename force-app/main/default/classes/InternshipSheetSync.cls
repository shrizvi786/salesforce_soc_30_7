public with sharing class InternshipSheetSync {

    @future(callout=true)
    public static void syncmondayData() {

        List<Internship__c> monday = [
            SELECT Name, Student_First_Name__c,
                   Name_of_Org__c, Student_Last_Name__c,
                   Name_of_supervisor_s__c,
                   Monday_A_P_O_L__c,
                   Monday_date__c,
                   Monday_time_in__c,
                   Monday_time_out__c,
            Monday_Total_Time__c,
                   Supervisor_form_URL__c,
                   For_supervisor_URL_real__c
            FROM Internship__c
            WHERE Type__c = 'Internship'
        ];

        Map<String, Object> dataMap = new Map<String, Object>{
            'monday' => monday
        };

        String jsonBody = JSON.serialize(dataMap);

        HttpRequest req = new HttpRequest();

        // ✅ use custom label instead of hardcoded URL
        req.setEndpoint(System.Label.Internship_sheet_sync_api);

        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response from API: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }
    
        @future(callout=true)
    public static void synctuesdayData() {

        List<Internship__c> tuesday = [
			SELECT Name,Student_First_Name__c,Name_of_Org__c,Student_Last_Name__c,Name_of_supervisor_s__c,
            Tuesdday_A_P_O_L__c ,Tuesday_date__c,Tuesday_time_in__c,Tuesday_time_out__c,
            Tuesday_Total_Hours__c, Supervisor_form_URL__c,For_supervisor_URL_real__c 
            FROM Internship__c where Type__c = 'Internship'  order by CreatedDate desc 
        ];

        Map<String, Object> dataMap = new Map<String, Object>{
            'tuesday' => tuesday
        };

        String jsonBody = JSON.serialize(dataMap);

        HttpRequest req = new HttpRequest();

        // ✅ use custom label instead of hardcoded URL
        req.setEndpoint(System.Label.Internship_sheet_sync_api);

        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response from API: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }    
    
        @future(callout=true)
    public static void syncwednesdayData() {

        List<Internship__c> wednesday = [
			SELECT Name,Student_First_Name__c,Name_of_Org__c,Student_Last_Name__c,Name_of_supervisor_s__c,
            Wednesday_A_P_O_L__c,Wednesday_date__c,Wednesday_time_in__c,Wednesday_time_out__c,Wednesday_Total_Hours__c,
            Supervisor_form_URL__c,For_supervisor_URL_real__c FROM Internship__c where Type__c = 'Internship'  order by CreatedDate desc 
        ];

        Map<String, Object> dataMap = new Map<String, Object>{
            'wednesday' => wednesday
        };

        String jsonBody = JSON.serialize(dataMap);

        HttpRequest req = new HttpRequest();

        // ✅ use custom label instead of hardcoded URL
        req.setEndpoint(System.Label.Internship_sheet_sync_api);

        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response from API: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }
            
        @future(callout=true)
    public static void syncthursdayData() {

        List<Internship__c> thursday = [
			SELECT Name,Student_First_Name__c,Name_of_Org__c,Student_Last_Name__c,Name_of_supervisor_s__c,
            Thursday_A_P_O_L__c, Thursday_date__c,Thursday_time_in__c,Thursday_time_out__c,Thursday_Total_Hours__c,
            Supervisor_form_URL__c,For_supervisor_URL_real__c FROM Internship__c where Type__c = 'Internship'  order by CreatedDate desc 
        ];

        Map<String, Object> dataMap = new Map<String, Object>{
            'thursday' => thursday
        };

        String jsonBody = JSON.serialize(dataMap);

        HttpRequest req = new HttpRequest();

        // ✅ use custom label instead of hardcoded URL
        req.setEndpoint(System.Label.Internship_sheet_sync_api);

        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response from API: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }
    
            @future(callout=true)
    public static void syncfridayData() {

        List<Internship__c> friday = [
			SELECT Name,Student_First_Name__c,Name_of_Org__c,Student_Last_Name__c,Name_of_supervisor_s__c,
            Friday_A_P_O_L__c, Friday_date__c,Friday_time_in__c,Friday_time_out__c,Friday_Total_Hours__c,
            Supervisor_form_URL__c,For_supervisor_URL_real__c FROM Internship__c where Type__c = 'Internship'  order by CreatedDate desc 
            ];
        Map<String, Object> dataMap = new Map<String, Object>{
            'friday' => friday
        };

        String jsonBody = JSON.serialize(dataMap);

        HttpRequest req = new HttpRequest();

        // ✅ use custom label instead of hardcoded URL
        req.setEndpoint(System.Label.Internship_sheet_sync_api);

        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response from API: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }
    
            @future(callout=true)
    public static void syncsaturdayData() {

        List<Internship__c> saturday = [
			SELECT Name,Student_First_Name__c,Name_of_Org__c,Student_Last_Name__c,Name_of_supervisor_s__c,Saturday_A_P_O_L__c,
            Saturday_date__c,Saturday_time_in__c,Saturday_time_out__c,Saturday_Total_Hours__c,
            Supervisor_form_URL__c,For_supervisor_URL_real__c FROM Internship__c where Type__c = 'Internship'  order by CreatedDate desc 
            ];
        Map<String, Object> dataMap = new Map<String, Object>{
            'saturday' => saturday
        };

        String jsonBody = JSON.serialize(dataMap);

        HttpRequest req = new HttpRequest();

        // ✅ use custom label instead of hardcoded URL
        req.setEndpoint(System.Label.Internship_sheet_sync_api);

        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response from API: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }
    
                @future(callout=true)
    public static void syncsupervisorSignedData() {

        List<Internship__c> supervisor_signed = [
			SELECT Name,Student_First_Name__c,Name_of_Org__c,Student_Last_Name__c,Name_of_supervisor_s__c,
            Monday_A_P_O_L__c,Monday_date__c,Monday_time_in__c,Monday_time_out__c,Monday_Total_Time__c, 
			Supervisor_form_URL__c,For_supervisor_URL_real__c,Student_Email__c,Supervisor_Signed__c,Timesheet_correct__c 
            FROM Internship__c where Type__c = 'Internship'  order by CreatedDate desc 
            ];
        Map<String, Object> dataMap = new Map<String, Object>{
            'supervisor_signed' => supervisor_signed
        };

        String jsonBody = JSON.serialize(dataMap);

        HttpRequest req = new HttpRequest();

        // ✅ use custom label instead of hardcoded URL
        req.setEndpoint(System.Label.Internship_sheet_sync_api);

        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Response from API: ' + res.getBody());
        } catch (Exception e) {
            System.debug('API Callout Failed: ' + e.getMessage());
        }
    }
}