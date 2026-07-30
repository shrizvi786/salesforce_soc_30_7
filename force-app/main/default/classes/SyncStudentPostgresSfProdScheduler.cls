global class SyncStudentPostgresSfProdScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // batch size
        integer batchSize = 150;
        
        Database.executeBatch(new SyncStudentPostgresSfProdBatch(),batchSize);
        
    }

}