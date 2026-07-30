@isTest
public class ApexJobStatusControllerTest {
    @isTest
    static void testApexJobStatusController() {
        // Create test ChildObjectApiName__c records
        List<ChildObjectApiName__c> testChildObjectList = new List<ChildObjectApiName__c>();
        for (Integer i = 0; i < 10; i++) {
            ChildObjectApiName__c testChildObject = new ChildObjectApiName__c(Name = 'TestChildObject' + i);
            testChildObjectList.add(testChildObject);
        }
        insert testChildObjectList;
        
        // Instantiate the ApexJobStatusController
        ApexJobStatusController controller = new ApexJobStatusController();
        
        // Verify the initial values in the controller
        System.assertEquals(true, controller.showStatus);
        System.assertEquals(0, controller.apexJobStatusList.size());
        System.assertEquals(10, controller.childObjectApiNames.size());
        System.assertEquals(10, controller.childObjectLabels.size());
        
        // Verify the childObjectApiNames values
        for (Integer i = 0; i < 10; i++) {
            String expectedChildObjectName = 'TestChildObject' + i;
            String actualChildObjectName = controller.childObjectApiNames[i];
            System.assertEquals(expectedChildObjectName, actualChildObjectName);
        }
        
        // Verify the childObjectLabels values
        for (Integer i = 0; i < 10; i++) {
            String expectedChildObjectLabel = null; // Modify this if you have specific labels to test
            String actualChildObjectLabel = controller.childObjectLabels[i];
            System.assertEquals(expectedChildObjectLabel, actualChildObjectLabel);
        }
        
        // Verify the retrieval of object describe and adding labels
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        
        for (ChildObjectApiName__c childObject : testChildObjectList) {
            Schema.SObjectType objectType = globalDescribe.get(childObject.Name);
            if (objectType != null) {
                Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                String expectedChildObjectLabel = objectDescribe.getLabel();
                String actualChildObjectLabel = controller.childObjectLabels[testChildObjectList.indexOf(childObject)];
                System.assertEquals(expectedChildObjectLabel, actualChildObjectLabel);
            }
        }
    }
}