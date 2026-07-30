@isTest(SeeAllData=true)
public class SyncStudentParentRelationshipTest {
@IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        Student_Parent_Relationship__c  primaryObject= new Student_Parent_Relationship__c(Student__c ='a1J4W00000DHXSzUAP');
        insert primaryObject;
        update primaryObject;
        delete primaryObject;
        Test.stopTest();         
    }   
}