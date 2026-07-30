/* Old Code 

//Class used for getting the Unique School Ids to sync bulk records of Student object in one go 
//Calling of Sync button press of main Student object
//
public class SyncBulkStudentRecordsCleanUpdate implements Database.Batchable<sObject>, Database.stateful { 
    public Map<Id, Student__c> mapSchoolIdToStudent = new Map<Id, Student__c>();
    public List<Id> accountIdList = new List<Id>();
    public Set<Id> uniqueIds = new Set<Id>();
    
    //In this Start method we are fetching all the Students from the student object where School id is not null
    public Database.QueryLocator start(Database.BatchableContext context) {
        //Sync should include all records belongs to current academic year
        String currentAcademicYear = getCurrentAcademicYear();
        if (Test.isRunningTest()) {
            return Database.getQueryLocator([SELECT Id, School__c FROM Student__c
                                             WHERE School__c != null 
                                             AND Academic_Year__c = :currentAcademicYear
                                             AND (has_App__c = 'Yes' OR has_Data_Dashboard__c = 'Yes')]);
        }
        return Database.getQueryLocator([SELECT Id, School__c FROM Student__c Where School__c != null AND Clean_Update__c >= LAST_N_DAYS:14]); //Past 2 weeks buffer 
    }
    
    //In this method we are getting distinct School Id list
    public void execute(Database.BatchableContext context, List<Student__c> scope) {
        //Adding school id in the map to get different schoolIds not duplicates              
        for (Student__c student : scope) {
            mapSchoolIdToStudent.put(student.School__c, student);
        }
        
        // Extracting unique School IDs from the map keys and storing them in uniqueIds
        uniqueIds = mapSchoolIdToStudent.keySet();
        System.debug('uniqueIds ----- ' + uniqueIds);
        System.debug('uniqueIds ----- ' + uniqueIds.size());
    }    
    
    //Finish Method
    public void finish(Database.BatchableContext context) {
        System.debug('Inside finish method'); 
        
        //Adding all the uniqueIds to the List of UniqueSchoolIds
        accountIdList.addAll(uniqueIds);
        System.debug('schoolIdStrings::' + accountIdList.size());
        //Calling SyncBulkStudentRecordsScheduler class with the list of School Ids
        
        // Prevent nested executeBatch calls in tests
        //if (!Test.isRunningTest()) {
        System.enqueueJob(new SyncBulkStudentRecordsScheduler(accountIdList));
        //}
        
        //System.enqueueJob(new SyncBulkStudentRecordsScheduler(accountIdList));
    }
    
    public static String getCurrentAcademicYear(Date overrideDate) {
        Date today = Date.today();
        Integer year = today.year();
        Integer month = today.month();
        
        if (month >= 9) {
            return year + '-' + String.valueOf(year + 1);
        } else {
            return (year - 1) + '-' + String.valueOf(year);
        }
    }
    
    // Overloaded original version
    public static String getCurrentAcademicYear() {
        return getCurrentAcademicYear(null);
    }
    
}
*/

// New Code 

//Class used for getting the Unique School Ids to sync bulk records of Student object in one go 
//Calling of Sync button press of main Student object
//
public class SyncBulkStudentRecordsCleanUpdate implements Database.Batchable<sObject>, Database.stateful { 
    public Map<Id, Student__c> mapSchoolIdToStudent = new Map<Id, Student__c>();
    public List<Id> accountIdList = new List<Id>();
    public Set<Id> uniqueIds = new Set<Id>();
    
    // Static variable to control test behavior
    public static Boolean runRealQueryInTest = false;
    
    //In this Start method we are fetching all the Students from the student object where School id is not null
    public Database.QueryLocator start(Database.BatchableContext context) {
        //Sync should include all records belongs to current academic year
        String currentAcademicYear = getCurrentAcademicYear();
          if (Test.isRunningTest() && !runRealQueryInTest) {
            return Database.getQueryLocator([SELECT Id, School__c FROM Student__c
                                             WHERE School__c != null 
                                             AND Academic_Year__c = :currentAcademicYear
                                             AND (has_App__c = 'Yes' OR has_Data_Dashboard__c = 'Yes')]);
        }
        return Database.getQueryLocator([SELECT Id, School__c FROM Student__c Where School__c != null AND Clean_Update__c >= LAST_N_DAYS:14]); //Past 2 weeks buffer 
    }
    
    //In this method we are getting distinct School Id list
    public void execute(Database.BatchableContext context, List<Student__c> scope) {
        //Adding school id in the map to get different schoolIds not duplicates              
        for (Student__c student : scope) {
            mapSchoolIdToStudent.put(student.School__c, student);
        }
        
        // Extracting unique School IDs from the map keys and storing them in uniqueIds
        uniqueIds = mapSchoolIdToStudent.keySet();
        System.debug('uniqueIds ----- ' + uniqueIds);
        System.debug('uniqueIds ----- ' + uniqueIds.size());
    }    
    
    //Finish Method
    public void finish(Database.BatchableContext context) {
        System.debug('Inside finish method'); 
        
        //Adding all the uniqueIds to the List of UniqueSchoolIds
        accountIdList.addAll(uniqueIds);
        System.debug('schoolIdStrings::' + accountIdList.size());
        //Calling SyncBulkStudentRecordsScheduler class with the list of School Ids
        
        // Prevent nested executeBatch calls in tests
        //if (!Test.isRunningTest()) {
        System.enqueueJob(new SyncBulkStudentRecordsScheduler(accountIdList));
        //}
        
        //System.enqueueJob(new SyncBulkStudentRecordsScheduler(accountIdList));
    }
    
    public static String getCurrentAcademicYear(Date overrideDate) {
        Date today = Date.today();
        Integer year = today.year();
        Integer month = today.month();
        Integer day = today.day();
    
        // New session starts from 8th July
        if (month > 7 || (month == 7 && day >= 8)) {
            return year + '-' + String.valueOf(year + 1);
        } else {
            return (year - 1) + '-' + String.valueOf(year);
        }
    }

    
    // Overloaded original version
    public static String getCurrentAcademicYear() {
        return getCurrentAcademicYear(null);
    }
}