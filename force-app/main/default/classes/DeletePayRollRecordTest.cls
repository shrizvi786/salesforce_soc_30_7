@isTest
public class DeletePayRollRecordTest {

    // Test method to cover the deletePayRoll method
    @isTest
    static void testDeletePayRoll() {
        // Create some test Payroll__c records with different email addresses
        List<Payroll__c> testPayrollRecords = new List<Payroll__c>();
        
        // Add test records with email addresses not in the exclusion list
        testPayrollRecords.add(new Payroll__c(Employee_Work_Email__c = 'john.doe@example.com',Name = 'Albert Barabas- 16K628- 10/19,10/20HD- WR220356875'));
        testPayrollRecords.add(new Payroll__c(Employee_Work_Email__c = 'jane.smith@example.com',Name = 'Albert Barabas- 16K628- 10/19,10/20HD- WR220356875'));
        
        // Add test records with email addresses in the exclusion list
        testPayrollRecords.add(new Payroll__c(Employee_Work_Email__c = 'albert.barabas@solvedconsulting.com',Name = 'Albert Barabas- 16K628- 10/19,10/20HD- WR220356875'));
        testPayrollRecords.add(new Payroll__c(Employee_Work_Email__c = 'caroline.hopenwasser@solvedconsulting.com',Name = 'Albert Barabas- 16K628- 10/19,10/20HD- WR220356875'));
        
        // Insert the test records
        insert testPayrollRecords;

        // Call the deletePayRoll method
        DeletePayRollRecord.deletePayRoll();

        // Query the Payroll__c records after deletion
        List<Payroll__c> remainingRecords = [SELECT Id FROM Payroll__c];
        
        // Assert that only records with excluded email addresses remain
        System.assertEquals(2, remainingRecords.size(), 'Expected only records with excluded email addresses to remain after deletion');
    }
}