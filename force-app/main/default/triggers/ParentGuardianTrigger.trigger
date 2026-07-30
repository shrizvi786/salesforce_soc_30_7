trigger ParentGuardianTrigger on Student_Parent_Guardian__c (after insert) {
    // Store IDs of inserted records
    /*Set<Id> insertedRecordIds = new Set<Id>();
    for (Student_Parent_Guardian__c parentGuardian : Trigger.new) {
        insertedRecordIds.add(parentGuardian.Id);
    }

    // Query details of newly inserted records
    List<Student_Parent_Guardian__c> insertedRecords = [
        SELECT Id, Parent_Email__c, Students__c, Student__c
        FROM Student_Parent_Guardian__c
        WHERE Id IN :insertedRecordIds
    ];

    System.debug('Inserted Records: ' + insertedRecords);

    // Separate records with and without emails
    Set<String> parentEmails = new Set<String>();
    //Creating a list of records with no email as we will not consider that records to be duplicate
    List<Student_Parent_Guardian__c> noEmailRecords = new List<Student_Parent_Guardian__c>();

    for (Student_Parent_Guardian__c record : insertedRecords) {
        if (record.Parent_Email__c != null) {
            parentEmails.add(record.Parent_Email__c);
        } else {
            noEmailRecords.add(record); // Add records without email to a separate list
        }
    }

    // Query existing records with matching emails
    List<Student_Parent_Guardian__c> existingRecords = [
        SELECT Id, Parent_Email__c, Students__c, Student__c
        FROM Student_Parent_Guardian__c
        WHERE Parent_Email__c IN :parentEmails
    ];

    System.debug('Existing Records: ' + existingRecords);

    // Group records by parent email
    Map<String, List<Student_Parent_Guardian__c>> emailToParentGuardianMap = new Map<String, List<Student_Parent_Guardian__c>>();
    for (Student_Parent_Guardian__c record : existingRecords) {
        if (record.Parent_Email__c != null) {
            if (!emailToParentGuardianMap.containsKey(record.Parent_Email__c)) {
                emailToParentGuardianMap.put(record.Parent_Email__c, new List<Student_Parent_Guardian__c>());
            }
            emailToParentGuardianMap.get(record.Parent_Email__c).add(record);
        }
    }

    // Lists to track records to delete and update
    List<Student_Parent_Guardian__c> recordsToDelete = new List<Student_Parent_Guardian__c>();
    List<Student_Parent_Guardian__c> recordsToUpdate = new List<Student_Parent_Guardian__c>();

    // Deduplicate records based on email
    for (String email : emailToParentGuardianMap.keySet()) {
        List<Student_Parent_Guardian__c> parentGuardians = emailToParentGuardianMap.get(email);
        Student_Parent_Guardian__c primaryRecord = parentGuardians[0];

        for (Integer i = 1; i < parentGuardians.size(); i++) {
            Student_Parent_Guardian__c duplicateRecord = parentGuardians[i];
            if (duplicateRecord.Students__c != null) {
                if (primaryRecord.Students__c == null) {
                    primaryRecord.Students__c = duplicateRecord.Students__c;
                } else {
                    primaryRecord.Students__c += ',' + duplicateRecord.Students__c;
                }
            }
            recordsToDelete.add(duplicateRecord);
        }
        recordsToUpdate.add(primaryRecord);
    }

    System.debug('Records to Update (With Email): ' + recordsToUpdate);
    System.debug('Records to Delete: ' + recordsToDelete);

    // Update and delete records as necessary
    if (!recordsToUpdate.isEmpty()) {
        update recordsToUpdate;
    }

    if (!recordsToDelete.isEmpty()) {
        delete recordsToDelete;
    }

    // Handle records without emails and connect them to students
    List<Student_Parent_Guardian__c> nonDuplicateRecords = new List<Student_Parent_Guardian__c>();
    nonDuplicateRecords.addAll(noEmailRecords);
    nonDuplicateRecords.addAll(recordsToUpdate);

    // Collect unique student identifiers
    Set<String> studentIdentifiers = new Set<String>();
    for (Student_Parent_Guardian__c parentGuardian : nonDuplicateRecords) {
        if (parentGuardian.Students__c != null) {
            studentIdentifiers.addAll(parentGuardian.Students__c.split(','));
        }
        if (parentGuardian.Student__c != null) {
            studentIdentifiers.add(parentGuardian.Student__c);
        }
    }

    System.debug('Student Identifiers: ' + studentIdentifiers);

    // Query students based on identifiers
    List<Student__c> students = [
        SELECT Id, Student_ID__c, Student_Parent_Guardian_1__c, Student_Parent_Guardian_2__c
        FROM Student__c
        WHERE Student_ID__c IN :studentIdentifiers OR Id IN :studentIdentifiers
    ];

    System.debug('Students Fetched: ' + students);

    // Map to track students by their identifiers
    Map<String, Student__c> studentIdToStudentMap = new Map<String, Student__c>();
    Map<Id, Student__c> salesforceIdToStudentMap = new Map<Id, Student__c>();
    for (Student__c student : students) {
        studentIdToStudentMap.put(student.Student_ID__c, student);
        salesforceIdToStudentMap.put(student.Id, student);
    }

    System.debug('Student ID to Student Map: ' + studentIdToStudentMap);
    System.debug('Salesforce ID to Student Map: ' + salesforceIdToStudentMap);

    // Map to track students that need updating
    Map<Id, Student__c> studentUpdateMap = new Map<Id, Student__c>();

    // Link parent guardians to students
    for (Student_Parent_Guardian__c parentGuardian : nonDuplicateRecords) {
        List<String> studentIds = new List<String>();
        if (parentGuardian.Students__c != null) {
            studentIds.addAll(parentGuardian.Students__c.split(','));
        }
        if (parentGuardian.Student__c != null) {
            studentIds.add(parentGuardian.Student__c);
        }

        for (String studentId : studentIds) {
            studentId = studentId.trim();
            Student__c student = studentIdToStudentMap.get(studentId);

            if (student == null) {
                student = salesforceIdToStudentMap.get(studentId);
            }

            if (student != null) {
                if (student.Student_Parent_Guardian_1__c == null) {
                    student.Student_Parent_Guardian_1__c = parentGuardian.Id;
                } else if (student.Student_Parent_Guardian_2__c == null) {
                    student.Student_Parent_Guardian_2__c = parentGuardian.Id;
                }
                studentUpdateMap.put(student.Id, student);
            }
        }
    }

    System.debug('Students to Update: ' + studentUpdateMap.values());

    // Update the student records with assigned guardians
    if (!studentUpdateMap.isEmpty()) {
        update studentUpdateMap.values();
    }*/
}