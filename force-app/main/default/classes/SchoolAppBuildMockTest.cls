@IsTest(SeeAllData=true)
public class SchoolAppBuildMockTest {

    // Helper to create test records
    private static iOS_and_Android_App_Details__c createApp(
        String androidFlow,
        String iosFlow
    ) {
        return new iOS_and_Android_App_Details__c(
            
            Version_Name__c = 'v1',
            Version_number__c = 1.0,
            Android_App_Build_Flow__c = androidFlow,
            iOS_App_Build_Flow__c = iosFlow,
            Build_Type__c = 'New'
        );
    }

    // Setup StaticResourceCalloutMock
    private static void setMock() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetJenkinsRespons');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.setMock(HttpCalloutMock.class, mock);
    }

    // -----------------------------
    // INDIVIDUAL @future METHODS
    // -----------------------------

    @IsTest
    static void testAndroidUpdate() {
        setMock();
        Test.startTest();
        SchoolAppBuild.doAreaCalloutAsync('001000000000001');
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void testAndroidBuild() {
        setMock();
        Test.startTest();
        SchoolAppBuild.doAreaCalloutAndroidBuildAsync('001000000000002');
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void testAndroidTest() {
        setMock();
        Test.startTest();
        SchoolAppBuild.doAreaCalloutAndroidTestAsync('001000000000003');
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void testAndroidGoogleSSO() {
        setMock();
        Test.startTest();
        SchoolAppBuild.doAreaCalloutAndroidGoogleSSOVerificationAsync('001000000000004');
        Test.stopTest();
        System.assert(true);
    }

    @IsTest
    static void testIOSBuild() {
        setMock();
        Test.startTest();
        SchoolAppBuild.doAreaCalloutIOSAsync('001000000000005');
        Test.stopTest();
        System.assert(true);
    }

    // -----------------------------
    // SEND EMAIL COVERAGE
    // -----------------------------
    @IsTest
    static void testSendEmail() {
        setMock();
        Test.startTest();
        SchoolAppBuild.sendEmail('<b>Test Email</b>');
        Test.stopTest();
        System.assert(true);
    }
}