global class UpdateDistrictCleanSheetSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        UpdateDistrictCleanSheet udc = new UpdateDistrictCleanSheet();
        Database.executeBatch(udc);  
    }  
}