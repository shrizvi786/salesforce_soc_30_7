global class insert_tale_record_Schedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Call the sendData() method
        insert_tale_record.sendData();
    }
}