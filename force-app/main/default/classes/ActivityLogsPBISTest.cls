@isTest
public class ActivityLogsPBISTest implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        
        // Create a map response body for log counts
        Map<String, Object> bodyMap = new Map<String, Object>{
            'PBIS' => new Map<String, Object>{
                'Total_Sessions' => 10,
                    'Avg_Session_Duration' => '00:30',
                    'Total_Points_Awarded' => 100,
                    'Total_Session_Points_Awarded' => 90
                    },
                        'GRADED' => new Map<String, Object>{
                            'Total_Sessions' => 5,
                                'Avg_Session_Duration' => '00:20',
                                'Total_Assignments' => 50,
                                'Total_Student_Work_Scans' => 60
                                },
                                    'STUDENT' => new Map<String, Object>{
                                        'Total_Sessions' => 8,
                                            'Avg_Session_Duration' => '00:25',
                                            'Total_Student_Searches' => 30
                                            }
        };
            
            mockResponse.setBody(JSON.serialize(new Map<String, Object>{ 'body' => bodyMap }));
        return mockResponse;
    }
    
    @isTest
    static void testGetContactRecords() {
        // Create test data
        Contact testContact = new Contact(Email = 'techadmin@solvedconsulting.com', LastName = 'test', AccountId='0014W00002b4tUyQAI');
        insert testContact;
        
        // Set up test parameters
        String getUrl = testContact.Id;
        Integer offset = 0;
        Integer recLimit = 10;
        
        Test.setMock(HttpCalloutMock.class, new ActivityLogsPBISTest());
        
        Test.startTest();
        
        // Call the method under test
        List<Object> result = ActivityLogsPBIS.getContactRecords(getUrl, offset, recLimit);
        
        Test.stopTest();
        
        // Verify the result
       //////// System.assertEquals(3, result.size()); // Adjust this based on the expected number of interactions
        // Add more assertions based on your specific logic
        
        // Add assertions to cover the deserialization and processing section
        Map<String, Object> recordMap = (Map<String, Object>) result[0];
        String activityType = (String) recordMap.get('Activity_Type');
        String userEmail = (String) recordMap.get('Email');
        String activity_Id = (String) recordMap.get('Activity_Id');
        
        // Add assertions to verify the processed data
       
    }
}