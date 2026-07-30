trigger RegistrationTrigger on Registration__c (after insert, after update, after delete, after undelete) {

    if (Trigger.isAfter) {
        System.debug('Trigger executed for RegistrationTrigger');

        // Separate lists for each type
        List<Registration__c> reminderForms = new List<Registration__c>();
        List<Registration__c> lunchReflectionForms = new List<Registration__c>();

        if (Trigger.new != null) {
            for (Registration__c reg : Trigger.new) {

                // Check if Reminders form is true
                if (reg.X15K676_Reminders_Form__c == true) {
                    reminderForms.add(reg);
                }

                // Check if Lunch Reflection form is true
                if (reg.X15K676_Lunch_Reflection_Form__c == true) {
                    lunchReflectionForms.add(reg);
                }
            }
        }

        // Call handlers only if we have matching records
        if (!reminderForms.isEmpty()) {
            RegistrationTriggerHandler.sendData();
        }

        if (!lunchReflectionForms.isEmpty()) {
            X15K676_Lunch_Reflection.sendData();
        }
    }
}