@isTest (seeAllData = FALSE)
public class RipplingEmailHandlerTest {
    
    @isTest
    public static void ripplingEmailHandlerTestMethod1() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) January 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            				'(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
        
      @isTest
    public static void ripplingEmailHandlerTestMethod2() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) February 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();  
    }
        
        @isTest
    public static void ripplingEmailHandlerTestMethod3() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) March 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
    @isTest
    public static void ripplingEmailHandlerTestMethod4() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) April 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
    @isTest
    public static void ripplingEmailHandlerTestMethod5() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) May 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
    @isTest
    public static void ripplingEmailHandlerTestMethod6() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) June 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
    @isTest
    public static void ripplingEmailHandlerTestMethod7() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) July 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
    @isTest
    public static void ripplingEmailHandlerTestMethod8() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) August 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
    @isTest
    public static void ripplingEmailHandlerTestMethod9() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) September 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
    @isTest
    public static void ripplingEmailHandlerTestMethod10() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) October 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
    @isTest
    public static void ripplingEmailHandlerTestMethod11() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) November 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
    @isTest
    public static void ripplingEmailHandlerTestMethod12() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ; 
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.fromAddress = 'test@test.com';
        email.subject = 'Test Subject';
        email.htmlBody = 'Workflow triggered for: Employee pay run\n'+
                              '(Pay run status changed from) None (/Pay run status changed from)\n'+
                              '(Pay run status changed to) PAID (/Pay run status changed to)\n'+
                              '(Changed on) December 22, 2023 at 10:38:07 AM PDT (/Changed on)\n'+
                              '(Pay run check date) 6/28/23 (/Pay run check date)\n'+
                              '(Pay run status new) PAID (/Pay run status new)\n'+
                              '(Employee Gross Pay) $0.70 (/Employee Gross Pay)\n'+
                              '(Added Manually) False (/Added Manually)\n'+
            '(Payroll Name) Test Payroll Name (/Payroll Name)\n'+
                              '(Employee Name) </a>Test Payroll Name (/Employee Name)\n'+
                              '(Employee Email) test.payroll@solvedconsulting.com (/Employee Email)';
        
        Test.startTest();
            RipplingEmailHandler reh = new RipplingEmailHandler();
            reh.handleInboundEmail(email, envelope);  
        Test.stopTest();
    }
    
}