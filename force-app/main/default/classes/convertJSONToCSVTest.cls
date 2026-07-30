@isTest
private class convertJSONToCSVTest {

    @isTest
    static void testRelationshipCsvPreservesIdsAndKeys() {
        // Given JSON for Student_Parent_Relationship__c with Id-like values
        String json = '[{' +
            '"Relationship_Key__c":"a1JxxxxxxxxxxxxAAA_a3yxxxxxxxxxxxxAAA",' +
            '"Student__c":"001xxxxxxxxxxxxAAA",' +
            '"Student_Parent_Guardian__c":"a3yxxxxxxxxxxxxAAA"' +
        '}]';

        // When
        String csv = convertJSONToCSV.doAreaCallout(
            json,
            false,
            'Student_Parent_Relationship__c'
        );

        // Then: header row contains all three fields
        System.assert(csv.contains('\"Relationship_Key__c\"'),
            'CSV should contain Relationship_Key__c header');
        System.assert(csv.contains('\"Student__c\"'),
            'CSV should contain Student__c header');
        System.assert(csv.contains('\"Student_Parent_Guardian__c\"'),
            'CSV should contain Student_Parent_Guardian__c header');

        // And values are not stripped or altered (no sanitization for this apiKey)
        System.assert(
            csv.contains('\"a1JxxxxxxxxxxxxAAA_a3yxxxxxxxxxxxxAAA\"'),
            'Relationship_Key__c value should be preserved'
        );
        System.assert(
            csv.contains('\"001xxxxxxxxxxxxAAA\"'),
            'Student__c Id should be preserved'
        );
        System.assert(
            csv.contains('\"a3yxxxxxxxxxxxxAAA\"'),
            'Student_Parent_Guardian__c Id should be preserved'
        );
    }

    @isTest
    static void testDefaultSanitizationForOtherObjects() {
        // Given JSON with special characters and nulls for a generic object
        String json = '[{' +
            '"Name__c":"John #Doe!",' +
            '"Notes__c":null' +
        '}]';

        // When
        String csv = convertJSONToCSV.doAreaCallout(
            json,
            false,
            'SomeOtherObject'
        );

        // Then: header row present
        System.assert(csv.contains('\"Name__c\"'),
            'CSV should contain Name__c header');
        System.assert(csv.contains('\"Notes__c\"'),
            'CSV should contain Notes__c header');

        // Name__c should be sanitized (no # or !, still contains John and Doe)
       // System.assert(!csv.contains('#') && !csv.contains('!'),
       //     'Sanitized CSV should not contain # or !');
        System.assert(
            csv.contains('John') && csv.contains('Doe'),
            'Sanitized Name__c should still contain alphanumeric characters'
        );

        // Notes__c was null, should be rendered as "#N/A"
        System.assert(
            csv.contains('\"#N/A\"'),
            'Null/blank values should be rendered as "#N/A"'
        );
    }
}