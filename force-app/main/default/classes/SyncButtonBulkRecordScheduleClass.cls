//Schedule the batch in queue and sync the data in background
public class SyncButtonBulkRecordScheduleClass implements Database.Batchable<sObject>, Database.AllowsCallouts  {
    public String recordsToSend; //list of records
    public Integer batchSize = 10;
    public String objectName;
    public String query; 
    public string relatedObjectName;
    public Map<String, Object> formulaFieldsDataMaps;
    
    public SyncButtonBulkRecordScheduleClass(String recordsToSend, string ObjectName,String relatedObjectName) {
        this.recordsToSend = recordsToSend;
        this.ObjectName = ObjectName;
        this.relatedObjectName = relatedObjectName;
    }
    
    public  Iterable<sObject> start(Database.BatchableContext context) {
        if(String.isBlank(relatedObjectName)){
            //Sync Main Object Records if 'relatedObjectName' is empty
            //
            system.debug('Inside null recID');
            query = 'SELECT Id FROM '+ ObjectName;    
        }
        else{
            //Sync Related Object Records Only
            system.debug('got related List recID');
            List<String> fieldNames = new List<String>();
            for (Schema.SObjectField field : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values()) 
            {
                fieldNames.add(field.getDescribe().getName());
            }
            if(objectName == 'Student__c'){
                query = 'SELECT Id FROM ' + objectName + ' WHERE ' + relatedObjectName + ' = :recordsToSend ' +
                    'AND Academic_Year__c = \'2024-2025\' ' +
                    'AND (has_App__c = \'Yes\' OR has_Data_Dashboard__c = \'Yes\')';
            }else{
                query = 'SELECT Id FROM '+ objectName + ' WHERE '+relatedObjectName+'= :recordsToSend';
            }
            
        } 
        System.debug('Query----' + query);         
        return Database.getQueryLocator(query);
    }
    
    //Used to manage and sync null values of any record as the list doesn't contains null fields and values
    public void execute(Database.BatchableContext context, List<sObject> batch) {
        
        system.debug('batch: '+batch);      
        system.debug('batch: '+batch.size());        
        
        //Checking and adding ids of each record in a list
        List<String> str = new List<String>();
        for(SObject data : batch){
            str.add((String) data.get('Id'));
        }
        
        System.debug('str values:' + str);
        System.debug('str values:' + str.size());
        //Fetch fields name
        List<String> fieldNames = new List<String>(); 
        
        //If object is student then fetching onlu specific required field to sync
        if(objectName == 'Student__c'){
            // Call a separate function to fetch specific required fields for Student__c object
            fieldNames = getStudentFields();
            System.debug('Fields of the Student Object' + fieldNames);
        }else{
            // Fetch all fields for other objects
            for(Schema.SObjectField field: Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().values())
            { 
                fieldNames.add(field.getDescribe().getName());
            }
        }
        
        
        system.debug('List of Field Names: '+fieldNames); 
        String query = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + objectName + ' WHERE Id IN :str'; 
        
        system.debug('Database Query: '+query); 
        List<SObject> recordRes = database.query(query);
        system.debug('Query Result to Sync Records '+recordRes);
        
        List<sObject> getAllRecords = new List<sObject>();
        List<Map<String, Object>> formulafieldVlauesList = new List<Map<String, Object>>();
        
        // Remove the system generated fields and adding null value to null fields
        for (sObject objRec : recordRes) {           
            // Check for missing fields removed from the list due to null value
            Map<String, Object> missingFieldValues = new Map<String, Object>();
            formulaFieldsDataMaps = new Map<String, Object>();
            for (String fieldName : fieldNames) {                
                if (!objRec.getPopulatedFieldsAsMap().containsKey(fieldName)) {
                    missingFieldValues.put(fieldName, null);
                    
                    //Missing fields comes up when checking for fields having null values but systemt generated field are readonly and cannont to be updatable.
                    missingFieldValues.remove('LastActivityDate'); 
                    missingFieldValues.remove('UserRecordAccessId');
                    missingFieldValues.remove('ConnectionReceivedId');
                    missingFieldValues.remove('ConnectionSentId');
                    //system.debug('After remove: '+missingFieldValues);  
                }
            }
            System.debug('missingFieldValues' + missingFieldValues);
            // Add missing fields to the record list
            for (String fieldName : missingFieldValues.keySet()) {
                Schema.DescribeFieldResult fieldDesc = objRec.getSobjectType().getDescribe().fields.getMap().get(fieldName).getDescribe();
                //System.debug('fieldDesc' + fieldDesc.getName());
                //Check for only updatable field which are not generated by system
                if (fieldDesc.isUpdateable()) {
                    objRec.put(fieldName, missingFieldValues.get(fieldName));                    
                }//Check and list formula fields having null values to make them sync to postgress
                else if(fieldDesc.isCalculated() && missingFieldValues.get(fieldName) == null){                            
                    //Adding formual field with null value in a object //will add {} in case no null formual field exist at the list index
                    formulaFieldsDataMaps.put(fieldName, null);                             
                }              
            } 
            //updating the object to a list
            System.debug('dataMaps'+ formulaFieldsDataMaps);
            //adding formula field to each records if missing
            formulafieldVlauesList.add(formulaFieldsDataMaps);
            getAllRecords.add(objRec);
        }
        
        //System.debug('formulafieldVlaues:' + formulafieldVlauesList);              
        // Serialize getAllRecords into JSON
        String serializedRecords = JSON.serialize(getAllRecords);
        
        // Deserialize the JSON into a list of objects
        List<Object> recordList = (List<Object>) JSON.deserializeUntyped(serializedRecords);
        System.debug('formulafieldVlauessize' + formulafieldVlauesList.size());            
        
        //recordList = mail list having all fields other than null formula fields
        for (Integer i = 0; i < recordList.size(); i++) {
            Map<String, Object> recordMap = (Map<String, Object>) recordList.get(i);
            // Ensure there are formula field values for this record
            if (i < formulafieldVlauesList.size()) {
                Map<String, Object> dataMap = formulafieldVlauesList.get(i);
                //Adding each key of dataMap in the main list object index
                for (String fieldName : dataMap.keySet()) {
                    // Check if the recordMap contains the same field name                        
                    recordMap.put(fieldName, dataMap.get(fieldName));
                }
            }
        }
        
        
        // Serialize the modified list of objects back into JSON
        String updatedSerializedRecords = JSON.serialize(recordList);
        //System.debug('updatedSerializedRecords: *************' + updatedSerializedRecords);
        
        // Deserialize the JSON back into a list of sObjects
        List<sObject> updatedRecords = (List<sObject>) JSON.deserialize(updatedSerializedRecords, List<sObject>.class);
        System.debug('updatedRecords' + updatedRecords);
        
        //API Call To SYNC records
        Http http = new Http(); 
        HttpRequest req = new HttpRequest(); 
        req.setTimeout(60000);
        req.setMethod('POST');
        
        req.setBody(JSON.serialize(updatedRecords)); 
        req.setEndpoint('https://sfsync-service-api.solvedconsulting.net/production/save-records?objectName=' + objectName +'&isBulkData=true'); 
        req.setHeader('content-type', 'application/json;charset=UTF-8'); 
        req.setHeader('Authorization', 'REPLACE_WITH_AWS_AUTH_HEADER'); 
        HTTPResponse res = http.send(req); 
        if (res.getStatusCode() != 200) 
        { 
            System.debug('The status code returned was not expected: ' + res.getStatusCode() + ' ' + res.getStatus()); 
        } 
        else { 
            System.debug('last response'); 
            System.debug(res.getBody()); 
        }
    }
    
    public void finish(Database.BatchableContext context) {
        // Required but no action required in this example
    }
    
    
    // Define a separate function to fetch specific required fields for Student__c object
    public List<String> getStudentFields() {
        List<String> specificFields = new List<String>{
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
                'NYS_Math_Prediction__c',
                'NYS_ELA_Prediction__c',
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
                'Health_Insurance_Decription__c'
                };
                    return specificFields;
    }
}