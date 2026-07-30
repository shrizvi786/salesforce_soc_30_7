public class Sync_AccountMonday implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> accountIds;
    private String operation;
    
    // 🔴 PUT YOUR BOARD ID HERE
    private static final String BOARD_ID = '18400567380';
    
    private static final String DISTRICT_COLUMN_ID = 'text_mm0p89e6';
    private static final String STATUS_COLUMN_ID = 'status';
    private static final String SALESPERSON_COLUMN_ID = 'multiple_person_mm0q513h';
    private static final String PRINCIPAL_NAME_COLUMN_ID = 'text_mm0pvy5y';
    private static final String PRINCIPAL_EMAIL_COLUMN_ID = 'text_mm0p9029';
    private static final String WEBSITE_COLUMN_ID = 'link_mm0ptt7r';
    private static final String CURRENT_YEAR = '25-26';
    
    // Helper to compare school years like '24-25', '25-26' (returns true if currentYear > existingYear)
    private static Boolean isNewerSchoolYear(String currentYear, String existingYear) {
        if (String.isBlank(currentYear)) return false;
        if (String.isBlank(existingYear)) return true;
        
        List<String> currentParts = currentYear.replace('/', '-').split('-');
        List<String> existingParts = existingYear.replace('/', '-').split('-');
        
        Integer currentStart = Integer.valueOf(currentParts[0]);
        Integer existingStart = Integer.valueOf(existingParts[0]);
        
        return currentStart > existingStart;
    }

    // Derives school year string from Product_Service_End_Date__c: 2028 -> '27-28', 2027 -> '26-27'
    private static String schoolYearFromEndDate(Date endDate) {
        if (endDate == null) return null;
        Integer y = endDate.year();
        String first = String.valueOf(y - 1).right(2);
        String second = String.valueOf(y).right(2);
        return first + '-' + second;
    }
    
    public Sync_AccountMonday(Set<Id> accountIds, String operation) {
        this.accountIds = accountIds;
        this.operation = operation;
    }
    public void execute(QueueableContext context) {
        
        List<Account> accounts = [
            SELECT Id,
            DBN__c,
            District__r.District_Name__c,Principal__c,
       Principal_Email__c,
       Website
            FROM Account
            WHERE Id IN :accountIds
            AND (Type != 'Other' OR Type = null)
        ];
        
        if (accounts.isEmpty()) return;
        
        // Fetch ALL existing Monday items once
        Map<String, String> dbnToItemId = getMondayItems();
        
        if (operation == 'UPSERT') {
            handleUpsert(accounts, dbnToItemId);
        }
        
        if (operation == 'DELETE') {
            handleDelete(accounts, dbnToItemId);
        }
    }
    
    // =====================
    // DBN Status - Logic
    // =====================
    
  /*  private Map<String, String> getDbnToStatusMap(Set<String> dbns) {
        
        Map<String, String> dbnToStatus = new Map<String, String>();
        
        if (dbns.isEmpty()) return dbnToStatus;
        
        Set<String> excludedStages = new Set<String>{
            'Closed',
                'Pending',
                'Canceled',
                'Deferred Budget July',
                'Opportunity Stages Not Accepted'
                };
                    
                    List<Opportunity> opps = [
                        SELECT DBN_Formula__c,
                        School_Year__c,
                        StageName
                        FROM Opportunity
                        WHERE DBN_Formula__c IN :dbns
                    ];
        
        Map<String, List<Opportunity>> dbnToOpps = new Map<String, List<Opportunity>>();
        
        for (Opportunity opp : opps) {
            
            if (String.isBlank(opp.DBN_Formula__c)) continue;
            
            if (!dbnToOpps.containsKey(opp.DBN_Formula__c)) {
                dbnToOpps.put(opp.DBN_Formula__c, new List<Opportunity>());
            }
            
            dbnToOpps.get(opp.DBN_Formula__c).add(opp);
        }
        
        for (String dbn : dbnToOpps.keySet()) {
            
            List<Opportunity> dbnOpps = dbnToOpps.get(dbn);
            
            Boolean hasCurrentYear = false;
            Boolean hasPreviousYear = false;
            Boolean allClosed = true;
            
            for (Opportunity opp : dbnOpps) {
                
                if (opp.StageName != 'Closed') {
                    allClosed = false;
                }
                
                if (!excludedStages.contains(opp.StageName)) {
                    
                    if (opp.School_Year__c == CURRENT_YEAR) {
                        hasCurrentYear = true;
                    } else {
                        hasPreviousYear = true;
                    }
                }
            }
            
            if (allClosed) {
                dbnToStatus.put(dbn, 'Do Not Contact');
            }
            else if (hasCurrentYear) {
                dbnToStatus.put(dbn, 'Partner');
            }
            else if (hasPreviousYear) {
                dbnToStatus.put(dbn, 'Ex-Partner');
            }
        }
        
        return dbnToStatus;
    }*/
    
    @TestVisible
    private static Map<String, Map<String, String>> getDbnStatusAndSalespersonMap(Set<String> dbns) {

    Map<String, Map<String, String>> result = new Map<String, Map<String, String>>();

    if (dbns.isEmpty()) return result;

    Set<String> excludedStages = new Set<String>{
        'Closed',
        'Pending',
        'Canceled',
        'Deferred Budget July',
        'Opportunity Stages Not Accepted'
    };

    List<Opportunity> opps = [
        SELECT DBN_Formula__c,
               School_Year__c,
               Product_Service_End_Date__c,
               StageName,
               Salesperson__c
        FROM Opportunity
        WHERE DBN_Formula__c IN :dbns
    ];

    Map<String, List<Opportunity>> dbnToOpps = new Map<String, List<Opportunity>>();

    for (Opportunity opp : opps) {

        if (String.isBlank(opp.DBN_Formula__c)) continue;

        if (!dbnToOpps.containsKey(opp.DBN_Formula__c)) {
            dbnToOpps.put(opp.DBN_Formula__c, new List<Opportunity>());
        }

        dbnToOpps.get(opp.DBN_Formula__c).add(opp);
    }

    for (String dbn : dbnToOpps.keySet()) {

        List<Opportunity> dbnOpps = dbnToOpps.get(dbn);

        Boolean allClosed = true;

        Set<String> partnerSales = new Set<String>();
        Set<String> exPartnerSales = new Set<String>();
        Set<String> closedSales = new Set<String>();
        String highestYear = null;

        for (Opportunity opp : dbnOpps) {

            if (opp.StageName != 'Closed') {
                allClosed = false;
            }

            if (opp.Salesperson__c != null) {
                closedSales.add(opp.Salesperson__c);
            }

            if (!excludedStages.contains(opp.StageName)) {

                String oppYear = null;

                if (opp.Product_Service_End_Date__c != null) {
                    oppYear = schoolYearFromEndDate(opp.Product_Service_End_Date__c);
                } else if (String.isNotBlank(opp.School_Year__c)) {
                    oppYear = opp.School_Year__c;
                }

                if (oppYear == null) {
                    continue;
                }

                if (highestYear == null || isNewerSchoolYear(oppYear, highestYear)) {
                    highestYear = oppYear;
                }

                Boolean isPartnerYear =
                    oppYear == CURRENT_YEAR ||
                    isNewerSchoolYear(oppYear, CURRENT_YEAR);

                if (opp.Salesperson__c != null) {
                    if (isPartnerYear) {
                        partnerSales.add(opp.Salesperson__c);
                    } else {
                        exPartnerSales.add(opp.Salesperson__c);
                    }
                }
            }
        }

        String finalStatus;
        Set<String> finalSales;

        if (highestYear != null) {
            Boolean isPartnerYear =
                highestYear == CURRENT_YEAR ||
                isNewerSchoolYear(highestYear, CURRENT_YEAR);

            if (isPartnerYear) {
                finalStatus = 'Partner';
                finalSales =
                    !partnerSales.isEmpty()
                    ? partnerSales
                    : closedSales;
            } else {
                finalStatus = 'Ex-Partner';
                finalSales =
                    !exPartnerSales.isEmpty()
                    ? exPartnerSales
                    : closedSales;
            }
        } else if (allClosed) {
            finalStatus = 'Not Started';
            finalSales = closedSales;
        } else {
            continue;
        }

        List<String> sortedSales = new List<String>(finalSales);
        sortedSales.sort();

        Map<String, String> innerMap = new Map<String, String>();
        innerMap.put('status', finalStatus);
        innerMap.put('salespersons', String.join(sortedSales, ', '));

        result.put(dbn, innerMap);
    }

    return result;
}
    
    
    private static Map<String, String> getSalespersonToMondayIdMap() {

    Map<String, String> mapping = new Map<String, String>();

    for (Monday_User_Mapping__mdt rec :
         [SELECT Salesperson_Name__c, Monday_User_Id__c
          FROM Monday_User_Mapping__mdt]) {

        mapping.put(
            rec.Salesperson_Name__c,
            rec.Monday_User_Id__c
        );
    }

    return mapping;
}



    
    
    // ===============================
    // UPSERT
    // ===============================
    
    private void handleUpsert(
        List<Account> accounts,
        Map<String, String> dbnToItemId
    ) {
        
        Set<String> dbns = new Set<String>();
        for (Account acc : accounts) {
            if (!String.isBlank(acc.DBN__c)) {
                dbns.add(acc.DBN__c);
            }
        }
        
        Map<String, Map<String,String>> dbnData = getDbnStatusAndSalespersonMap(dbns);
        Map<String, String> salesToIdMap = getSalespersonToMondayIdMap();
        
        for (Account acc : accounts) {
            
            if (String.isBlank(acc.DBN__c)) continue;
            
            String itemId = dbnToItemId.get(acc.DBN__c);
            
            if (itemId == null) {
                itemId = createMondayItem(acc.DBN__c);
            }
            
            if (itemId != null) {
                
                Map<String, Object> columnValues =
                    new Map<String, Object>();
                
                String districtName =
                    acc.District__r != null
                    ? acc.District__r.District_Name__c
                    : null;
                
                columnValues.put(DISTRICT_COLUMN_ID, districtName);
                
                // 🔹 Principal Name
if (acc.Principal__c != null) {
    columnValues.put(
        PRINCIPAL_NAME_COLUMN_ID,
        acc.Principal__c
    );
}

// 🔹 Principal Email
if (acc.Principal_Email__c != null) {
    columnValues.put(
        PRINCIPAL_EMAIL_COLUMN_ID,
        acc.Principal_Email__c
    );
}

// 🔹 School Website (Link column requires special format)
if (acc.Website != null) {

    String website =
        acc.Website.startsWith('http')
        ? acc.Website
        : 'https://' + acc.Website;

    Map<String, Object> linkValue =
        new Map<String, Object>{
            'url' => website,
            'text' => website
        };

    columnValues.put(
        WEBSITE_COLUMN_ID,
        linkValue
    );
}
                
                if (dbnData.containsKey(acc.DBN__c)) {

    Map<String,String> dbnInfo =
        dbnData.get(acc.DBN__c);

    columnValues.put(
        STATUS_COLUMN_ID,
        dbnInfo.get('status')
    );
   
	 

    String salespersonText = dbnInfo.get('salespersons');

    // 🔹 Populate People column if mapping exists
    if (salespersonText != null) {

        Set<String> salesNames =
            new Set<String>(
                salespersonText.split(', ')
            );

        List<Object> personsList =
            new List<Object>();

        for (String name : salesNames) {

            if (salesToIdMap.containsKey(name)) {

                personsList.add(
                    new Map<String, Object>{
                        'id' => salesToIdMap.get(name),
                        'kind' => 'person'
                    }
                );
            }
        }

        if (!personsList.isEmpty()) {

            Map<String, Object> peopleValue =
                new Map<String, Object>{
                    'personsAndTeams' => personsList
                };

            columnValues.put(
                SALESPERSON_COLUMN_ID,
                peopleValue
            );
        }
    }
}

                
                updateMondayItemMultipleColumns(
                    itemId,
                    columnValues
                );
            }
    
        }
    }
    
    
    // ===============================
    // DELETE
    // ===============================
    
    private void handleDelete(
        List<Account> accounts,
        Map<String, String> dbnToItemId
    ) {
        
        for (Account acc : accounts) {
            
            if (String.isBlank(acc.DBN__c)) continue;
            
            String itemId = dbnToItemId.get(acc.DBN__c);
            
            if (itemId != null) {
                deleteMondayItem(itemId);
            }
        }
    }
    
    // ===============================
    // GET ALL MONDAY ITEMS
    // ===============================
    
    /* private Map<String, String> getMondayItems() {

Map<String, String> dbnToItemId =
new Map<String, String>();

HttpRequest req = buildRequest(
'query { boards(ids: [' + BOARD_ID + ']) ' +
'{ items_page(limit: 500) { items { id name } } } }'
);

HttpResponse res = new Http().send(req);

if (res.getStatusCode() == 200) {

Map<String, Object> response =
(Map<String, Object>) JSON.deserializeUntyped(res.getBody());

Map<String, Object> data =
(Map<String, Object>) response.get('data');

List<Object> boards =
(List<Object>) data.get('boards');

if (!boards.isEmpty()) {

Map<String, Object> board =
(Map<String, Object>) boards[0];

Map<String, Object> itemsPage =
(Map<String, Object>) board.get('items_page');

List<Object> items =
(List<Object>) itemsPage.get('items');

for (Object obj : items) {

Map<String, Object> item =
(Map<String, Object>) obj;

dbnToItemId.put(
(String) item.get('name'),
(String) item.get('id')
);
}
}
}

return dbnToItemId;
} */
    
    private Map<String, String> getMondayItems() {
        
        Map<String, String> dbnToItemId = new Map<String, String>();
        
        String cursor = null;
        Boolean hasMore = true;
        
        while (hasMore) {
            
            String query;
            
            if (cursor == null) {
                
                query =
                    'query { boards(ids: [' + BOARD_ID + ']) ' +
                    '{ items_page(limit: 500) { ' +
                    'cursor ' +
                    'items { id name } ' +
                    '} } }';
                
            } else {
                
                query =
                    'query { next_items_page(limit: 500, cursor: "' + cursor + '") { ' +
                    'cursor ' +
                    'items { id name } ' +
                    '} }';
            }
            
            HttpRequest req = buildRequest(query);
            HttpResponse res = new Http().send(req);
            
            if (res.getStatusCode() != 200) {
                System.debug('Error fetching Monday items: ' + res.getBody());
                break;
            }
            
            Map<String, Object> response =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (response == null) break;

            Map<String, Object> data =
                (Map<String, Object>) response.get('data');
            if (data == null) break;

            Map<String, Object> itemsPage;
            
            if (cursor == null) {
                
                List<Object> boards =
                    (List<Object>) data.get('boards');
                
                if (boards == null || boards.isEmpty()) break;
                
                Map<String, Object> board =
                    (Map<String, Object>) boards[0];
                if (board == null) break;
                
                itemsPage =
                    (Map<String, Object>) board.get('items_page');
                
            } else {
                
                itemsPage =
                    (Map<String, Object>) data.get('next_items_page');
            }
            
            if (itemsPage == null) break;
            
            List<Object> items =
                (List<Object>) itemsPage.get('items');
            if (items == null) items = new List<Object>();
            
            for (Object obj : items) {
                
                Map<String, Object> item =
                    (Map<String, Object>) obj;
                
                dbnToItemId.put(
                    (String) item.get('name'),
                    (String) item.get('id')
                );
            }
            
            cursor = (String) itemsPage.get('cursor');
            
            if (cursor == null) {
                hasMore = false;
            }
        }
        
        return dbnToItemId;
    }
    
    // ===============================
    // CREATE ITEM
    // ===============================
    
    private String createMondayItem(String dbn) {
        
        HttpRequest req = buildRequest(
            'mutation { create_item(' +
            'board_id: ' + BOARD_ID +
            ', item_name: "' + dbn + '"' +
            ') { id } }'
        );
        
        HttpResponse res = new Http().send(req);
        
        if (res.getStatusCode() == 200) {
            
            Map<String, Object> response =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            Map<String, Object> data =
                (Map<String, Object>) response.get('data');
            if (data == null) {
                return null;
            }
            
            Map<String, Object> createItem =
                (Map<String, Object>) data.get('create_item');
            
            if (createItem == null) return null;
            
            return (String) createItem.get('id');
        }
        
        return null;
    }
    
    // ===============================
    // UPDATE MULTIPLE COLUMNS
    // ===============================
    
    private void updateMondayItemMultipleColumns(
        String itemId,
        Map<String, Object> columnValues
    ) {
        
        if (columnValues == null || columnValues.isEmpty()) return;
        
        String columnJson =
            JSON.serialize(columnValues).replace('"', '\\"');
        
        String query =
            'mutation { change_multiple_column_values(' +
            'item_id: ' + itemId +
            ', board_id: ' + BOARD_ID +
            ', column_values: "' + columnJson + '"' +
            ') { id } }';
        
        HttpRequest req = buildRequest(query);
        
        new Http().send(req);
    }
    
    // ===============================
    // DELETE ITEM
    // ===============================
    
    private void deleteMondayItem(String itemId) {
        
        HttpRequest req = buildRequest(
            'mutation { delete_item(item_id: ' +
            itemId +
            ') { id } }'
        );
        
        new Http().send(req);
    }
    
    // ===============================
    // COMMON REQUEST BUILDER
    // ===============================
    
    private HttpRequest buildRequest(String query) {
        
        String token = getMondayAPIToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.monday.com/v2');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        
        req.setBody(JSON.serialize(
            new Map<String, Object>{ 'query' => query }
        ));
        
        return req;
    }
    
    // ===============================
    // TOKEN LOADER (Same as yours)
    // ===============================
    
    private static String getMondayAPIToken() {
        
        if (Test.isRunningTest()) {
            return 'test-token';
        }
        
        StaticResource tokenResource =
            [SELECT Body FROM StaticResource
             WHERE Name = 'MondayAPIToken'
             LIMIT 1];
        
        return tokenResource.Body.toString().trim();
    }
}