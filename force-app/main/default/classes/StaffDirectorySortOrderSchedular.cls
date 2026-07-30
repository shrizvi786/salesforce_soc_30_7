/* -- TEst Class name  is  : - StaffDirectorySortOrderSchedularTest*/
public class StaffDirectorySortOrderSchedular implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Call the updateSortOrderByLastName method
        StaffDirectorySortOrder.updateSortOrderByLastName();
    }

}