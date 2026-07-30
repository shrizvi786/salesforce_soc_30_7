trigger CtlePdRegistrantTrigger on CTLE_Registrants__c  (after insert, after update, after delete, after undelete) {
    


    if (Trigger.isAfter) {
        System.debug('Trigger executed for CtlePdRegistrantTrigger');
        CtlePdRegistrantHandler.sendData();
    }

}