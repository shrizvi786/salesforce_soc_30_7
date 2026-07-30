trigger AccountTriggertimezone on Account (after update) {
    List<Id> accountsToUpdate = new List<Id>();

    System.debug('Account trigger invoked.');

    for (Account updatedAccount : Trigger.new) {
        Account oldAccount = Trigger.oldMap.get(updatedAccount.Id);
        
        if (oldAccount != null && updatedAccount.BillingPostalCode != oldAccount.BillingPostalCode) {
            System.debug('BillingPostalCode changed for Account: ' + updatedAccount.Id);
            accountsToUpdate.add(updatedAccount.Id);
        }
    }

    if (!accountsToUpdate.isEmpty()) {
        System.debug('Accounts with changed BillingPostalCode: ' + accountsToUpdate);
        ZipCodeChangeBatch batch = new ZipCodeChangeBatch(accountsToUpdate);
        Database.executeBatch(batch);
    }
}