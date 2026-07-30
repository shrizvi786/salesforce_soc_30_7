global class SyncStudentPostgresSfProdBatch
implements Database.Batchable<SObject>, Database.AllowsCallouts,Database.Stateful {

    private List<String> fieldNames;
    private Boolean hasError = false;
    private String errorMessage;
    private Integer totalProcessed = 0;

    // Constructor
    global SyncStudentPostgresSfProdBatch() {
        fieldNames = getStudentFields();
    }

    // Start: build SOQL with specific fields only
    global Database.QueryLocator start(Database.BatchableContext bc) {

        String soql =
            'SELECT ' + String.join(fieldNames, ',') +
            ' FROM Student__c' +
            ' WHERE Clean_Update__c = TODAY';

        System.debug('Batch SOQL: ' + soql);
        return Database.getQueryLocator(soql);
    }

    // Execute: send chunk to Postgres
    global void execute(Database.BatchableContext bc, List<Student__c> scope) {

        if (scope.isEmpty()) return;

        try {
            String payload = JSON.serialize(scope);
            System.debug('Payload size (chars): ' + payload.length());

            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setTimeout(120000);
            req.setEndpoint(
                'https://sfsync-service-api.solvedconsulting.net/production/save-records' +
                '?objectName=Student__c&isBulkData=true'
            );
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER');
            req.setBody(payload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                hasError = true;
                if (errorMessage == null) {
                    errorMessage =
                        'Postgres sync failed. Status: ' +
                        res.getStatusCode() + ' Body: ' + res.getBody();
                }
                System.debug('❌ ' + errorMessage);
            } else {
                totalProcessed += scope.size();
                System.debug('✅ Synced records count: ' + scope.size());
            }
        }
        catch (Exception e) {
            hasError = true;
            if (errorMessage == null) {
                errorMessage = 'Exception during Postgres sync: ' + e.getMessage();
            }
            System.debug('❌ ' + errorMessage);
        }
    }

    // Finish: send ONE Slack notification
    global void finish(Database.BatchableContext bc) {

        if (hasError) {
            sendSlackNotification(
                '❌ Salesforce Student Object → SF-PROD Postgres batch sync FAILED.\n' +
                errorMessage
            );
        }
        else if (totalProcessed == 0) {
            sendSlackNotification(
                '⚠️ Salesforce Student Object → SF-PROD Postgres batch sync completed.\n' +
                'No records matched Clean_Update__c = TODAY.'
            );
        }
        else {
            sendSlackNotification(
                '✅ Salesforce Student Object → SF-PROD Postgres batch sync completed successfully.\n' +
                'Total records synced: ' + totalProcessed
            );
        }

        System.debug(
            'Batch completed. Error = ' + hasError +
            ', Total Records Synced = ' + totalProcessed
        );
    }

    // ---- STUDENT FIELD LIST ----
    private static List<String> getStudentFields() {
        return new List<String>{
            'Id',
                'First_Name__c',
                'last_Name__c',
                'Last_Name_INITCAP__c',
                'First_Name_INITCAP__c',
                'Grade__c',
                'DBN__c',
                'Parent_Phone__c',
                'School__c',
                'Student_ID__c',
                'Email__c',
                'Class__c',
                'Academic_Year__c',
                'IEP_Formula__c',
                'Date_of_Birth_Formula__c',
                'NYS_ELA_2019__c',
                'NYS_Math_2019__c',
                'NYS_ELA_PR_Score_2022__c',
                'NYS_ELA_2021__c',
                'NYS_Math_2021__c',
               // 'NYS_Math_Prediction__c',
               //  'NYS_ELA_Prediction__c',
                'NYS_ELA_PR_Score_2023__c',
                'NYS_Math_PR_Score_2023__c',
                'iReady_Math_EOY_Previous_SY_ORP_STUDENT__c',
                'IReady_Math_BOY_ORP_STUDENT__c',
                'IReady_Math_MOY_ORP_STUDENT__c',
                'iReady_Math_EOY_22_23_Percentile__c',
                'IReady_MATH_BOY_Percentile__c',
                'IReady_MATH_MOY_Percentile__c',
                'iReady_Math_EOY_Previous_SY_Percentile__c',
                'iReady_ELA_EOY_22_23_ORP_STUDENT__c',
                'IReady_ELA_BOY_ORP_STUDENT__c',
                'IReady_ELA_MOY_ORP_STUDENT__c',
                'iReady_ELA_EOY_Previous_SY_ORP_STUDENT__c',
                'iReady_ELA_EOY_22_23_Percentile__c',
                'IReady_ELA_BOY_Percentile__c',
                'IReady_ELA_MOY_Percentile__c',
                'iReady_ELA_EOY_Previous_SY_Percentile__c',
                'IEP_Yes_No__c',
                'Teacher_Proper__c',
                'Ethnicity_Name__c',
                'IReady_ELA_BOY_Overall_Relative_Place__c',
                'YTD_Attendance_Rate_Description__c',
                'Age__c',
                'Grade_19_20__c',
                'Grade_20_21__c',
                'Grade_21_22__c',
                'Grade_22_23__c',
                'Student_photo__c',
                'MAP_Math_EOY_22_23_Level__c',
                'MAP_Math_BOY_Level_Previous_SY__c',
                'MAP_Math_MOY_Level_Previous_SY__c',
                'MAP_Math_EOY_Previous_SY_Level__c',
                'MAP_Math_EOY_22_23_Percentile__c',
                'MAP_MATH_BOY_Percentile_Previous_SY__c',
                'MAP_MATH_MOY_Percentile_Previous_SY__c',
                'MAP_Math_EOY_Previous_SY_Percentile__c',
                'MAP_ELA_EOY_22_23_Level__c',
                'MAP_ELA_BOY_Level_Previous_SY__c',
                'MAP_ELA_MOY_Level_Previous_SY__c',
                'MAP_ELA_EOY_Previous_SY_Level__c',
                'MAP_ELA_EOY_22_23_Percentile__c',
                'MAP_ELA_BOY_Percentile_Previous_SY__c',
                'MAP_ELA_MOY_Percentile_Previous_SY__c',
                'MAP_ELA_EOY_Previous_SY_Percentile__c',
                'Sex__c',
                'Clean_Update__c',
                'Total_Days_Absent__c',
                'Current_Attendance__c',
                'Home_Language_Description__c',
                'Housing_Status__c',
                'LastModifiedDate',
                'ELL_Yes_No__c',
                'Sex_Name__c',
                'YTD_Attendance_Rate_Code__c',
                'DOE_Last_Update__c',
                'Ethnicity_Description__c',
                'Ethnicity_Code__c',
                'DOB_RESI__c',
                'ELL_Proficiency_Code__c',
                'Race_Description__c',
                'Teacher__c',
                'transportation_desc__c',
                'NYS_Math_Score_2022__c',
                'enter_nyc_date__c',
                'Custom_Barcode_Id__c',
                'Student_Parent_Guardian_1__c',
                'Student_Parent_Guardian_2__c',
                'Grade_23_24__c',
                'NYS_Math_PR_Score_2024__c',
                'NYS_ELA_PR_Score_2024__c',
                'iReady_ELA_BOY_Score__c',
                'iReady_ELA_MOY_Score__c',
                'iReady_ELA_EOY_Score__c',
                'IReady_ELA_EOY_Percentile__c',
                'IReady_ELA_EOY_ORP_STUDENT__c',
                'iReady_Math_BOY_Score__c',
                'iReady_Math_MOY_Score__c',
                'iReady_Math_EOY_Score__c',
                'IReady_MATH_EOY_Percentile__c',
                'IReady_Math_EOY_ORP_STUDENT__c',
                'MAP_ELA_EOY_Level__c',
                'MAP_ELA_MOY_Level__c',
                'MAP_ELA_BOY_Level__c',
                'MAP_ELA_EOY_Percentile__c',
                'MAP_ELA_MOY_Percentile__c',
                'MAP_ELA_BOY_Percentile__c',
                'MAP_Math_EOY_Level__c',
                'MAP_Math_MOY_Level__c',
                'MAP_Math_BOY_Level__c',
                'MAP_MATH_EOY_Percentile__c',
                'MAP_MATH_MOY_Percentile__c',
                'MAP_MATH_BOY_Percentile__c',
                'Acadience_Math_EoY_Previous_SY_Level__c',
                'Acadience_Math_BoY_Level__c',
                'Acadience_Math_MoY_Level__c',
                'Acadience_Math_EoY_Level__c',
                'Acadience_Math_EoY_Previous_SY_Score__c',
                'Acadience_Math_BoY_Score__c',
                'Acadience_Math_MoY_Score__c',
                'Acadience_Math_EoY_Score__c',
                'Acadience_ELA_EoY_Previous_SY_Level__c',
                'Acadience_ELA_BoY_Level__c',
                'Acadience_ELA_MoY_Level__c',
                'Acadience_ELA_EoY_Level__c',
                'Acadience_ELA_EoY_Previous_SY_Score__c',
                'Acadience_ELA_BoY_Score__c',
                'Acadience_ELA_MoY_Score__c',
                'Acadience_ELA_EoY_Score__c',
                'MAP_Math_EoY_Previous_SY_Score__c',
                'MAP_Math_BoY_Score__c',
                'MAP_Math_MoY_Score__c',
                'MAP_Math_EoY_Score__c',
                'MAP_ELA_EoY_Previous_SY_Score__c',     
                'MAP_ELA_BoY_Score__c',
                'MAP_ELA_MoY_Score__c',
                'MAP_ELA_EoY_Score__c',
                'iReady_Math_EoY_Previous_SY_Score__c',
                'iReady_ELA_EoY_Previous_SY_Score__c',
                'Class_Code_Numeric__c',
                'DBN_Numeric__c',
                'Class_and_DBN_Numeric__c',
                'NYS_ELA_PR_Score_2025__c',
                'NYS_Math_PR_Score_2025__c',
                'Health_Alert_Description__c',
                'Health_Immunization__c',
                'Health_Insurance_Decription__c',
                'ELL_Proficiency_Level__c',
                'YTD_Attendance_Present__c',
                'Admission_Date__c',
                'Admission_Date_Formatted__c',
                'Total_School_Days__c',
                'Current_Attendance_formula__c',
                'YTD_Attendance_Late__c'
        };
    }

    // ---- SLACK NOTIFICATION ----
    private void sendSlackNotification(String message) {

        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(
            'https://hooks.slack.com/services/REPLACE_WITH_SLACK_WEBHOOK'
        );
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(
            JSON.serialize(new Map<String, Object>{ 'text' => message })
        );

        try {
            http.send(request);
        } catch (Exception e) {
            System.debug('Slack notification failed: ' + e.getMessage());
        }
    }
}