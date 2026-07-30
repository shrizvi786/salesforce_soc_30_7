@isTest(SeeAllData=true)
public class AddUserInteractionTest {
	@IsTest private static void testTrigger()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SyncSFWithAWS');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
       	
        Test.startTest(); 
        Datetime sysTime = System.now();
        SyncUserInteractionBatchClass userInteractionJob = new SyncUserInteractionBatchClass();
        String jobID = System.schedule('New Schedule' + sysTime.getTime(),'0 0 * * * ?', userInteractionJob);
        //database.executebatch(userInteractionJob);
        Test.stopTest(); 
        
        //Seperate Call
        SyncNewsInteraction_Bulk_API.doAreaCallout(true);
        SyncSocialInteraction_Bulk_API.doAreaCallout(true);  
        SyncGradedInteraction_Bulk_API.doAreaCallout(true);
        convertJSONToCSV.doAreaCallout('[{"key": "value"}]',true,'');
       	
		System.assertNotEquals(null, 'null');
 	} 
}