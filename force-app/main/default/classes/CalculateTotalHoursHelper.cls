public class CalculateTotalHoursHelper {
    // Flag to prevent recursive trigger execution
    public static Boolean isTriggerExecuting = false;
    
    
    public static List<Product_Service_Update__c> calculateAndUpdateTotalHours(List<Product_Service_Update__c> recordsToUpdate) {
        // List to store updated records
        List<Product_Service_Update__c> recordsToUpdateWithHours = new List<Product_Service_Update__c>();
        
        // Loop through provided records
        for (Product_Service_Update__c record : recordsToUpdate) {
            // Convert Request_Came_in__c to a DateTime
            Datetime requestDateTime = Datetime.valueOf(record.Request_Came_in__c);
            
            // Calculate the day of the week for Request_Came_in__c
            Integer requestDayOfWeek = Integer.valueOf(requestDateTime.format('u'));
            system.debug('requestDayOfWeek' +requestDayOfWeek);
            system.debug('requestDayOfWeek' +requestDayOfWeek);
            // Check if it's Saturday (6) or Sunday (7)
            if (requestDayOfWeek == 6 || requestDayOfWeek == 7) {
                // Treat it as Monday at 9 AM (assuming CreatedDate is always a weekday)
                //Datetime monday9AM = requestDateTime.addDays(7 - requestDayOfWeek).addHours(9);
                Datetime monday9AM = DateTime.newInstance(requestDateTime.year(), requestDateTime.month(), requestDateTime.day() + (7 - requestDayOfWeek), 9, 0, 0);
                
                system.debug('monday9AM' +monday9AM);
                Decimal durationInHours = calculateTotalHours(monday9AM, record.CreatedDate);
                
                // Create an updated record with calculated Duration__c
                Product_Service_Update__c updatedRecord = new Product_Service_Update__c(
                    Id = record.Id,
                    Duration__c = durationInHours
                );
                
                // Add the updated record to the list
                recordsToUpdateWithHours.add(updatedRecord);
            } else {
                // Use the existing logic to calculate Duration__c
                Decimal durationInHours = calculateTotalHours(requestDateTime, record.CreatedDate);
                
                // Create an updated record with calculated Duration__c
                Product_Service_Update__c updatedRecord = new Product_Service_Update__c(
                    Id = record.Id,
                    Duration__c = durationInHours
                );
                
                // Add the updated record to the list
                recordsToUpdateWithHours.add(updatedRecord);
            }
        }
        
        // Update the records with new Duration__c values
        update recordsToUpdateWithHours;
        return recordsToUpdateWithHours;
    }
    
    // Method to calculate total hours between start and end date-times
    public static Decimal calculateTotalHours(DateTime startDateTime, DateTime endDateTime) {
        system.debug('startDateTime'+startDateTime);
        system.debug('endDateTime' +endDateTime);
        // Calculate time difference in milliseconds
        Long timeDifferenceMillis = endDateTime.getTime() - startDateTime.getTime();
        
        // Calculate total hours using time difference
        Decimal totalHours = timeDifferenceMillis / (1000 * 60 * 60);
        
        // Calculate total minutes using time difference and subtracting hours
        Long totalMinutes = (timeDifferenceMillis / (1000 * 60)) - (totalHours.intValue() * 60);
        
        
        // Iterate through days to subtract weekends
        while (startDateTime < endDateTime) {
            if (startDateTime.format('E') == 'Sat' || startDateTime.format('E') == 'Sun') {
                totalHours -= 24;
            }
            startDateTime = startDateTime.addDays(1);
        } 
        
        
        
        
        // Add remaining minutes as fractional hours
        totalHours += totalMinutes / 60.0;
        
            // Ensure totalHours is positive
    totalHours = Math.abs(totalHours);
        
        
        system.debug('totalHours' + totalHours);
        
        // Return the calculated total hours
        return totalHours;
    }
}