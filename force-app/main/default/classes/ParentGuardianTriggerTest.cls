@isTest
public class ParentGuardianTriggerTest {
    
    @testSetup
    static void setupTestData() {
        try{
            // Set the mock for the callout
            Test.setMock(HttpCalloutMock.class, new MockStudentCallout());
            
            // Create test student records
            List<Student__c> students = new List<Student__c>();
            for (Integer i = 0; i < 3; i++) {
                students.add(new Student__c(Grade__c = '06 ' + i));
            }
            insert students;
            
        }catch(Exception e){
            
        }        
    }
    
    @isTest
    static void testInsertAndUpdateParentGuardian() {
        try{
            // Set the mock for the callout
            Test.setMock(HttpCalloutMock.class, new MockStudentCallout());
            List<Student__c> students = [SELECT Id FROM Student__c LIMIT 3];
            
            System.debug('Fetched students: ' + students);
            
            // Create Parent-Guardian records with different emails
            List<Student_Parent_Guardian__c> parentGuardians = new List<Student_Parent_Guardian__c>();
            parentGuardians.add(new Student_Parent_Guardian__c(Parent_Email__c = 'parent1@example.com'));
            
            System.debug('Prepared parentGuardians list');
            
            // Start the test context
            Test.startTest();
            System.debug('Starting Test Context');
            
            // Insert Parent-Guardian records
            insert parentGuardians;
            System.debug('Inserted parentGuardians');
            
            // Stop the test context
            Test.stopTest();
            System.debug('Stopped Test Context');
            
        }catch(Exception e){
            System.debug('error');
        }   
    }
    
    // Define the mock callout class outside the test class
    public class MockStudentCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            return res;
        }
    }
}