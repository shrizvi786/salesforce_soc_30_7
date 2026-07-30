// ===============================
// TestDataFactory.cls
// ===============================
@IsTest
public class TestDataFactory {

    // Creates and inserts a fully populated Account with unique DBN and Slack ID
    public static Account createAccount(Integer index, String dbn) {
        Account acc = new Account(
            Name = 'Test Account ' + index,
            DBN__c = dbn,
            Principal__c = 'Test Principal ' + index,
            Principal_Email__c = 'principal' + index + '@test.com',
            Dashboard_DBN_URL__c = 'https://dashboard' + index + '.link',
            App_POCs__c = 'app' + index + '@example.com',
            Branding_POCs__c = 'brand' + index + '@example.com',
            Coaching_POCs__c = 'coach' + index + '@example.com',
            Data_PoC_Emails__c = 'data' + index + '@example.com',
            Online_CTLE_Course_POCs__c = 'online' + index + '@example.com',
            Photo_Video_POCs__c = 'photo' + index + '@example.com',
            Website_POCs__c = 'web' + index + '@example.com',
            Slack_Channel_ID__c = 'SLACK' + index
        );
        insert acc;
        return acc;
    }

    // Creates an Opportunity with required fields (NOT inserted)
    public static Opportunity makeOpportunity(
        Id accountId,
        String productService,
        Date endDate,
        String stageName
    ) {
        return new Opportunity(
            Name = 'Opp - ' + productService,
            AccountId = accountId,
            StageName = stageName,
            CloseDate = Date.today(),
            School_Year__c = '25-26',
            Product_Service__c = productService,
            Amount = 1500,
            Work_Order_Sent_Date__c = Date.today(),
            Product_Service_Start_Date__c = Date.today(),
            Product_Service_End_Date__c = endDate,
            Salesperson__c = 'Matias Brocato',
            Vendor__c = 'SOL352471'
        );
    }

    // Convenience: create + insert one Opportunity
    public static Opportunity createOpportunity(
        Id accountId,
        String productService,
        Date endDate,
        String stageName
    ) {
        Opportunity o = makeOpportunity(accountId, productService, endDate, stageName);
        insert o;
        return o;
    }
}