@isTest
private class SyncParentLoginStatsBatchTest {

    private static HttpResponse buildJsonResponse(Integer totalCount, List<Object> rows) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody(JSON.serialize(new Map<String, Object>{
            'statuscode' => 200,
            'totalCount' => totalCount,
            'body' => rows
        }));
        return res;
    }

    private static Datetime makeDateTime(
        Integer year,
        Integer month,
        Integer day,
        Integer hour,
        Integer minute,
        Integer second
    ) {
        return Datetime.newInstance(
            Date.newInstance(year, month, day),
            Time.newInstance(hour, minute, second, 0)
        );
    }

    private static String directGuardianKey() {
        return '0123456789SerenaDoe';
    }

    private static String fallbackGuardianKey() {
        return '+919876543210AliceONeil';
    }

    private class MainBatchMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            String url = req.getEndpoint();

            if (url.contains('limit=1')) {
                return buildJsonResponse(101, new List<Object>());
            }

            if (url.contains('offset=0')) {
                return buildJsonResponse(101, new List<Object>{
                    new Map<String, Object>{
                        'parent_phones__c' => '0123456789',
                        'Parent_First_Name__c' => 'Serena',
                        'Parent_Last_Name__c' => 'Doe',
                        'phone_guardian__c' => '0123456789_Serena-Doe!',
                        'Total_Logins__c' => 5,
                        'Last_Login_At__c' => '2024-12-13 11:22:40.696271'
                    },
                    new Map<String, Object>{
                        'parent_phones__c' => '+91_987-654-3210',
                        'Parent_First_Name__c' => 'Alice',
                        'Parent_Last_Name__c' => 'O\'Neil',
                        'phone_guardian__c' => null,
                        'Total_Logins__c' => '7',
                        'Last_Login_At__c' => '2024-08-23T12:08:07.999999'
                    },
                    new Map<String, Object>{
                        'parent_phones__c' => '7777777777',
                        'Parent_First_Name__c' => 'Bob',
                        'Parent_Last_Name__c' => 'Jones',
                        'phone_guardian__c' => '7777777777BobJones',
                        'Total_Logins__c' => 'not-a-number',
                        'Last_Login_At__c' => '2024-13-40 11:22:40'
                    },
                    new Map<String, Object>{
                        'parent_phones__c' => '8888888888',
                        'Parent_First_Name__c' => 'No',
                        'Parent_Last_Name__c' => 'Total',
                        'phone_guardian__c' => '8888888888NoTotal',
                        'Last_Login_At__c' => null
                    },
                    new Map<String, Object>{
                        'parent_phones__c' => '9999999999',
                        'Parent_First_Name__c' => 'Bad',
                        'Parent_Last_Name__c' => 'Date',
                        'phone_guardian__c' => '9999999999BadDate',
                        'Total_Logins__c' => '3',
                        'Last_Login_At__c' => '2024/12/13 11:22:40'
                    },
                    new Map<String, Object>{
                        'parent_phones__c' => '6666666666',
                        'Parent_First_Name__c' => 'Short',
                        'Parent_Last_Name__c' => 'Time',
                        'phone_guardian__c' => '6666666666ShortTime',
                        'Total_Logins__c' => '8',
                        'Last_Login_At__c' => '2024-12-13 11:22'
                    },
                    new Map<String, Object>{
                        'parent_phones__c' => '5555555555',
                        'Parent_First_Name__c' => 'Date',
                        'Parent_Last_Name__c' => 'Only',
                        'phone_guardian__c' => '5555555555DateOnly',
                        'Total_Logins__c' => '2',
                        'Last_Login_At__c' => '2024-12-13'
                    },
                    new Map<String, Object>{
                        'parent_phones__c' => '',
                        'Parent_First_Name__c' => 'Skip',
                        'Parent_Last_Name__c' => 'Blank',
                        'phone_guardian__c' => 'shouldSkip',
                        'Total_Logins__c' => 99
                    },
                    new Map<String, Object>{
                        'parent_phones__c' => '---',
                        'Parent_First_Name__c' => null,
                        'Parent_Last_Name__c' => null,
                        'phone_guardian__c' => null,
                        'Total_Logins__c' => 1
                    },
                    new Map<String, Object>{
                        'parent_phones__c' => '1111111111',
                        'Parent_First_Name__c' => 'No',
                        'Parent_Last_Name__c' => 'Match',
                        'phone_guardian__c' => '1111111111NoMatch',
                        'Total_Logins__c' => 4,
                        'Last_Login_At__c' => '2024-02-03 04:05:06'
                    }
                });
            }

            if (url.contains('offset=100')) {
                return buildJsonResponse(101, new List<Object>());
            }

            return buildJsonResponse(101, new List<Object>());
        }
    }

    private class EmptyRowsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            return buildJsonResponse(0, new List<Object>());
        }
    }

    private class AllRowsSkippedMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            return buildJsonResponse(1, new List<Object>{
                new Map<String, Object>{
                    'parent_phones__c' => '',
                    'Parent_First_Name__c' => 'Skip',
                    'Parent_Last_Name__c' => 'Me',
                    'phone_guardian__c' => null,
                    'Total_Logins__c' => 1
                },
                new Map<String, Object>{
                    'parent_phones__c' => '---',
                    'Parent_First_Name__c' => null,
                    'Parent_Last_Name__c' => null,
                    'phone_guardian__c' => null,
                    'Total_Logins__c' => 2
                }
            });
        }
    }

    private class NoMatchingRowsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            return buildJsonResponse(1, new List<Object>{
                new Map<String, Object>{
                    'parent_phones__c' => '1231231234',
                    'Parent_First_Name__c' => 'No',
                    'Parent_Last_Name__c' => 'Match',
                    'phone_guardian__c' => '1231231234NoMatch',
                    'Total_Logins__c' => '6',
                    'Last_Login_At__c' => '2024-10-11 12:13:14'
                }
            });
        }
    }

    private class FailingExecuteMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated API failure');
        }
    }


    @isTest
    static void testStartBuildsOffsetsAndFinishRuns() {
        Test.setMock(HttpCalloutMock.class, new MainBatchMock());

        List<Integer> offsets = new List<Integer>();
        for (Integer offset : new SyncParentLoginStatsBatch().start(null)) {
            offsets.add(offset);
        }

        System.assertEquals(2, offsets.size());
        System.assertEquals(0, offsets[0]);
        System.assertEquals(100, offsets[1]);

        new SyncParentLoginStatsBatch().finish(null);
    }

    @isTest
    static void testExecuteHandlesGuardClausesAndFailures() {
        new SyncParentLoginStatsBatch().execute(null, null);
        new SyncParentLoginStatsBatch().execute(null, new List<Integer>());

        Test.setMock(HttpCalloutMock.class, new EmptyRowsMock());
        new SyncParentLoginStatsBatch().execute(null, new List<Integer>{ 0 });

        Test.setMock(HttpCalloutMock.class, new AllRowsSkippedMock());
        new SyncParentLoginStatsBatch().execute(null, new List<Integer>{ 0 });

        Test.setMock(HttpCalloutMock.class, new NoMatchingRowsMock());
        new SyncParentLoginStatsBatch().execute(null, new List<Integer>{ 0 });

        Test.setMock(HttpCalloutMock.class, new FailingExecuteMock());
        new SyncParentLoginStatsBatch().execute(null, new List<Integer>{ 0 });
    }
}