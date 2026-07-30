public class TALE_ParticipationAlias {
    public String participantFirstName { get; set; }
    public String participantLastName { get; set; }
    public Decimal numberOfHoursCredits { get; set; }
    public Date attendanceDate { get; set; }
    public Date awardedDate { get; set; }
    public String dbn { get; set; }
    public String lastFourSSN { get; set; }
    public String participantEmail { get; set; }
    public String email { get; set; }
    public String sessionType { get; set; }
    public String facilitator {get; set;}
    public String courseName {get; set;}
    public Date dateOfBirth {get; set;}
    // Constructor to populate fields based on a TALE_Participation__c record
    public TALE_ParticipationAlias(TALE_Participation__c participationRecord) {
        this.participantFirstName = participationRecord.First_name__c;
        this.participantLastName = participationRecord.Last_Name__c;
        this.numberOfHoursCredits = 1;
        this.attendanceDate = participationRecord.Date_Attended__c;
        this.awardedDate = participationRecord.Date_Attended__c;
        this.dbn = participationRecord.DBN__c;
        this.lastFourSSN = participationRecord.SSN__c;
        this.participantEmail = participationRecord.Email__c;
        //  this.email = participationRecord.Email__c;
        this.facilitator = participationRecord.Facilitator__c;
        this.courseName = participationRecord.TALE_Course__r.Name;
        this.dateOfBirth = participationRecord.Date_of_Birth__c;
        this.sessionType = 'Synchronous TALE Course';
       
        
        
        
        // You'll need to map the other fields accordingly based on your schema
        // ...
    }
}