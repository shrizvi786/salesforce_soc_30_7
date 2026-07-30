global class RipplingEmailHandler implements Messaging.InboundEmailHandler {
      global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
          Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
          
          
          String emailFromAddress = email.fromAddress;
          String emailSubject = email.Subject; 
          String emailContent = email.htmlBody; 
          String textEmailContent = email.plainTextBody;
          
          Boolean addedManuallyBoolean;
          
          Datetime formattedDatetime;
          Date formattedDate;
          
          system.debug('----emailContent----'+emailContent);
          system.debug('----textEmailContent----'+textEmailContent);
          
          String startingTags = '(';
          String endingTags = ')';
          
          
          String oldPayrollStatus = emailContent.substringBetween(startingTags+'Pay run status changed from'+endingTags, startingTags+'/Pay run status changed from'+endingTags).trim();
          
          
          String newPayrollStatus = emailContent.substringBetween(startingTags+'Pay run status changed to'+endingTags, startingTags+'/Pay run status changed to'+endingTags).trim();
          
          
          String changedOn = emailContent.substringBetween(startingTags+'Changed on'+endingTags, startingTags+'/Changed on'+endingTags).trim();
          if(changedOn.containsIgnoreCase('January')) {
              changedOn = changedOn.replace('January ', '01/');
          }
          if(changedOn.containsIgnoreCase('February')) {
              changedOn = changedOn.replace('February ', '02/');
          }
          if(changedOn.containsIgnoreCase('March')) {
              changedOn = changedOn.replace('March ', '03/');
          }
          if(changedOn.containsIgnoreCase('April')) {
              changedOn = changedOn.replace('April ', '04/');              
          }
          if(changedOn.containsIgnoreCase('May')) {
              changedOn = changedOn.replace('May ', '05/');
          }
          if(changedOn.containsIgnoreCase('June')) {
              changedOn = changedOn.replace('June ', '06/');
          }
          if(changedOn.containsIgnoreCase('July')) {
              changedOn = changedOn.replace('July ', '07/');
          }
          if(changedOn.containsIgnoreCase('August')) {
              changedOn = changedOn.replace('August ', '08/');
          }
          if(changedOn.containsIgnoreCase('September')) {
              changedOn = changedOn.replace('September ', '09/');
          }
          if(changedOn.containsIgnoreCase('October')) {
              changedOn = changedOn.replace('October ', '10/');
          }
          if(changedOn.containsIgnoreCase('November')) {
              changedOn = changedOn.replace('November ', '11/'); 
          }
          if(changedOn.containsIgnoreCase('December')) {
              changedOn = changedOn.replace('December ', '12/');
          }
          if(changedOn.containsIgnoreCase(', ')){
              changedOn = changedOn.replace(', ', '/');
          }
          if(changedOn.containsIgnoreCase(' at')){
              changedOn = changedOn.replace(' at', ',');
          }
          if(changedOn.containsIgnoreCase('AM')){
              changedOn = changedOn.substring(0, changedOn.lastIndexOf('AM')-4) + ' AM';
          }
          if(changedOn.containsIgnoreCase('PM')){
              changedOn = changedOn.substring(0, changedOn.lastIndexOf('PM')-4) + ' PM';
          }
          if(changedOn != null && changedOn != ''){
              formattedDatetime = datetime.parse(changedOn);
          }
          
          String payRunCheckDate = emailContent.substringBetween(startingTags+'Pay run check date'+endingTags, startingTags+'/Pay run check date'+endingTags).trim();
          formattedDate = Date.parse(payRunCheckDate);
          
          String payRunStatusNew = emailContent.substringBetween(startingTags+'Pay run status new'+endingTags, startingTags+'/Pay run status new'+endingTags).trim();
          
          String employeeGrossPay = emailContent.substringBetween(startingTags+'Employee Gross Pay'+endingTags, startingTags+'/Employee Gross Pay'+endingTags).remove('$').remove(',').trim();
          
          String addedManually = emailContent.substringBetween(startingTags+'Added Manually'+endingTags, startingTags+'/Added Manually'+endingTags).trim();
          addedManuallyBoolean = Boolean.valueOf(addedManually);
          
          String payrollName = emailContent.substringBetween(startingTags+'Payroll Name'+endingTags, startingTags+'/Payroll Name'+endingTags).trim();
          
          String employeeName = emailContent.substringBetween(startingTags+'Employee Name'+endingTags, startingTags+'/Employee Name'+endingTags).trim();
          
          String employeeEmail = emailContent.substringBetween(startingTags+'Employee Email'+endingTags, startingTags+'/Employee Email'+endingTags).trim();
          
          String employeeEmail2;
          if(employeeEmail.contains('</a>')) {
              employeeEmail2 = employeeEmail.substring(employeeEmail.indexOf('">')+2, employeeEmail.indexOf('</a>')).trim(); 
          } 
          
              
          Payroll__c newPayroll = new Payroll__c();
          //newPayroll.Name = 'Payroll for '+employeeName;
          newPayroll.Name = (payrollName != null && payrollName != '' ?payrollName:'Payroll for '+employeeName);
          newPayroll.Old_Payroll_Status__c = oldPayrollStatus;  
          newPayroll.New_Payroll_Status__c = newPayrollStatus;
          newPayroll.Effective_Date__c = formattedDatetime;
          newPayroll.Payroll_Check_date__c = formattedDate;
          newPayroll.Employee_Gross_Pay__c = Decimal.valueOf(employeeGrossPay);
          newPayroll.Added_Manually__c = addedManuallyBoolean; 
          newPayroll.Employee_Name__c = employeeName;
          if(employeeEmail.contains('</a>')) {
              newPayroll.Employee_Work_Email__c = employeeEmail2;
          }
          else{
             newPayroll.Employee_Work_Email__c = employeeEmail; 
          } 
          
          try {
              INSERT newPayroll;    
              result.success = true;
              result.message = 'A new Payroll record, '+newPayroll.Name+', has been created successfully.';
          }
          catch(Exception e) {
              result.message = 'Error creating a new Payroll record: \n'+e.getMessage();
          }
             
          return result;
      }
  }