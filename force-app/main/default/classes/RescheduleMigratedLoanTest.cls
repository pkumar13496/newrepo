@isTest
public class RescheduleMigratedLoanTest{

    @testSetup static void setup() {
        
        loan__Org_Parameters__c orgParam = new loan__Org_Parameters__c();
        orgParam.loan__Disable_Triggers__c=true;
        orgParam.loan__Digits_After_Decimals__c=2;
        orgParam.loan__Rounding_Mode__c='Nearest';
        insert orgParam;
        
        loan.TestHelper.systemDate = Date.today();
        loan.TestHelper.createSeedDataForTesting();
        loan.TestHelper.setupApprovalProcessForTxn();
        loan__Currency__c curr = loan.TestHelper.createCurrency();
        //dummy account
        loan__MF_Account__c dummyAccount = loan.TestHelper.createMFAccount('XXXAccountForTest', '10000 - ASSETS');
        loan__MF_Account__c dummyIncAccount = loan.TestHelper.createMFAccount('XXXIncAccountForTest', '30000 - INCOME');
        
        //dummy office
        loan__Office_Name__c dummyOffice = loan.TestHelper.createOffice();
        
        //dummy fee
        loan__Fee__c dummyFee = loan.TestHelper.createFee(curr, dummyIncAccount, dummyAccount);
        loan__Fee_Set__c dummyFeeSet = loan.TestHelper.createFeeSet();
        loan__Fee_Junction__c dummyFeeJunction = loan.TestHelper.createFeeJunction(dummyFee, dummyFeeSet);
        
        //creating lending product
        //loan__Loan_Product__c dummyLP = loan.TestHelper.createLoanProduct(dummyOffice, dummyAccount, curr, dummyFeeSet);
        Id prodRTId = Schema.SObjectType.loan__Loan_Product__c.getRecordTypeInfosByName().get('Loan Product Record Type').getRecordTypeId();
        loan__Loan_Product__c dummyLP =new loan__Loan_Product__c();
        dummyLP.Name ='Unsecured Personal Loan';
        dummyLP.loan__Interest_Calculation_Method__c='Declining Balance';
        dummyLP.loan__Frequency_of_Loan_Payment__c='Monthly';
        dummyLP.loan__Accrual_Start_Basis__c='Contract Date';
        dummyLP.loan__Payment_Application_Mode__c='Future Dues';
        dummyLP.loan__Fee_Set__c=dummyFeeSet.id;
        dummyLP.loan__Currency__c=curr.id;
        dummyLP.loan__Loan_Product_Type__c='Loan';
        dummyLP.loan__Pre_Bill_Days__c=2;
        dummyLP.loan__Status__c='Active';
        dummyLP.loan__Accrual_Based_Accounting__c=true;
        dummyLP.loan__Accrue_Income_On_Suspended_Account__c=true;
        dummyLP.loan__Cash_Based_Accounting__c=false;
        dummyLP.loan__Maximum_Gap_Between_Installments__c=1;
        dummyLP.loan__Minimum_Gap_Between_Installments__c=1;
        dummyLP.loan__Max_Loan_Amount__c=30000;
        dummyLP.loan__Max_Overdue_Interest_Rate__c=24;
        dummyLP.loan__Minimum_Installment_Amount__c=100;
        dummyLP.loan__Min_Interest_Rate__c=1;
        dummyLP.loan__Min_Loan_Amount__c=0;
        dummyLP.loan__Min_Number_of_Installments__c=0;
        dummyLP.loan__Min_Overdue_Interest_Rate__c=10;
        dummyLP.loan__Product_Interest_Income_Account__c=dummyAccount.id;
        dummyLP.loan__Product_Int_On_Overdue_Income_Acc__c=dummyAccount.id;
        dummyLP.loan__Product_Loan_Control_Account__c=dummyAccount.id;
        dummyLP.loan__Product_Loan_Loss_Provision_Account__c=dummyAccount.id;
        dummyLP.loan__Product_Loan_Loss_Reserve_Account__c=dummyAccount.id;
        dummyLP.loan__Product_Overdue_Interest_Account__c=dummyAccount.id;
        dummyLP.loan__Product_Suspended_Interest_Account__c=dummyAccount.id;
        dummyLP.loan__Product_Suspended_Int_On_Overdue_Acc__c=dummyAccount.id;
        dummyLP.loan__Product_Write_Off_Recovery_Account__c=dummyAccount.id;
        dummyLP.loan__Product_Interest_Amortization_Account__c=dummyAccount.id;
        dummyLP.loan__Product_Excess_Account__c=dummyAccount.id;
        insert dummyLP;
        
        
        //dummy purpose
        loan__Loan_Purpose__c dummyLoanPurpose = loan.TestHelper.createLoanPurpose();
        
        //dummy Account
        Account acc = new Account();
        acc.Name = 'SKP';
        insert acc;
        
        //dummy contact 
        Contact a1 = new Contact(LastName='TestACH',MobilePhone='9672257740',AccountId=acc.id,Email='Test@gmail.com',Are_you_a_Resident_of_Canada__c='No');
        insert a1;
        
        //dummy contract
        loan__Loan_Account__c lacc = loan.TestHelper.createLoanAccountForContactObj(dummyLP,
                                                                                    a1,
                                                                                    dummyFeeSet,
                                                                                    dummyLoanPurpose,
                                                                                    dummyOffice); 

        lacc.loan__Principal_Remaining__c=400;
        lacc.isMigrated__c = true;
        update lacc;
        
        System.debug('Loan Status='+lacc.loan__Loan_Status__c);
        Test.startTest();
        
       
        loan__Payment_Mode__c paymentMode = [select id from loan__Payment_Mode__c where Name= 'Cash'];
        
        //loan Disbursal Txn
        loan__Loan_Disbursal_Transaction__c disTxn = new loan__Loan_Disbursal_Transaction__c();
        disTxn.loan__Disbursed_Amt__c = lacc.loan__Loan_Amount__c;
        disTxn.loan__Mode_of_Payment__c = paymentMode.Id;
        disTxn.loan__Loan_Account__c = lacc.Id;
        disTxn.loan__Disbursal_Date__c = loan.TestHelper.systemDate;
        insert disTxn;
        disTxn.loan__Cleared__c = true;
        update disTxn;
        
        //LPT for LS Contract
        loan__Loan_Payment_Transaction__c test_LPT1 = new loan__Loan_Payment_Transaction__c();
        test_LPT1.loan__Loan_Account__c = lacc.Id;
        test_LPT1.loan__Transaction_Amount__c = 200;
        test_LPT1.loan__Transaction_Date__c = System.today();
        test_LPT1.loan__Receipt_Date__c = System.today();
        test_LPT1.loan__Payment_Mode__c = paymentMode.Id;
        test_LPT1.loan__Cleared__c = true;
        //test_LPT1.loan_Is_Migrated__c = true ;
        insert test_LPT1;
        
        loan__Loan_Payment_Transaction__c test_LPT2 = new loan__Loan_Payment_Transaction__c();
        test_LPT2.loan__Loan_Account__c = lacc.Id;
        test_LPT2.loan__Transaction_Amount__c = 400;
        test_LPT2.loan__Transaction_Date__c = System.today();
        test_LPT2.loan__Receipt_Date__c = System.today();
        test_LPT2.loan__Payment_Mode__c = paymentMode.Id;
        test_LPT2.loan__Cleared__c = true;
        //test_LPT2.loan_Is_Migrated__c = true ;
        insert test_LPT2;
        
        //Create Bill
        loan__Loan_account_Due_Details__c test_bill1 = new loan__Loan_account_Due_Details__c();
        test_bill1.loan__Due_Type__c = 1;
        test_bill1.loan__Due_Type_Description__c = 'BILL / DUE DATE';
        test_bill1.loan__Loan_Account__c = lacc.Id;
        insert test_bill1;
        
        loan__Loan_account_Due_Details__c test_bill2 = new loan__Loan_account_Due_Details__c();
        test_bill2.loan__Due_Type__c = 1;
        test_bill2.loan__Due_Type_Description__c = 'BILL / DUE DATE';
        test_bill2.loan__Loan_Account__c = lacc.Id;
        test_bill2.loan__DD_Primary_Flag__c = True;
        test_bill2.loan__Payment_Satisfied__c = false ;
        insert test_bill2;
        
        loan__Loan_account_Due_Details__c test_bill3 = new loan__Loan_account_Due_Details__c();
        test_bill3.loan__Due_Type__c = 1;
        test_bill3.loan__Due_Type_Description__c = 'BILL / DUE DATE';
        test_bill3.loan__Loan_Account__c = lacc.Id;
        insert test_bill3;
        
        loan__Due_Payment__c due = new loan__Due_Payment__c(loan__Fees__c = null,
                                                         loan__Payment_Amount__c = null,
                                                         loan__Principal__c = null,
                                                         loan__Interest__c = null,
                                                         loan__Loan_Payment_Transaction__c = test_LPT1.id,
                                                         loan__Due__c = test_bill1.id
                                                         );
                                                         
        insert due;
        Test.stopTest();
    }
    
    
    Testmethod static void method1(){
    
    Date lastUnpaidDueDate = Date.newinstance(2020,04,01);
    Date lastPaidDueDate = Date.newinstance(2020,03,01);
    List<loan__Loan_Payment_Transaction__c> payments = new List<loan__Loan_Payment_Transaction__c>();
        
    Test.startTest();
        
        
    loan__Due_Payment__c DPD = [select id,name,loan__Due__c,loan__Loan_Payment_Transaction__c from loan__Due_Payment__c];
    loan__Loan_account_Due_Details__c oldestDuet = [select id,name from loan__Loan_account_Due_Details__c where id =: DPD.loan__Due__c];
       
    List<loan__Loan_Account__c> LAList = [SELECT ID,Name,loan__Pre_Bill_Days__c,
                                            loan__Principal_Remaining__c,
                                            loan__Principal_Paid__c,
                                            loan__Interest_Paid__c,  
                                          loan__Previous_Installment_Date__c,
                                          loan__Loan_Product_Name__r.name, 
                                          loan__Payment_Amount__c, 
                                          loan__Next_Installment_Date__c, 
                                          (select id,name,
                                          loan__Transaction_Date__c, 
                                          loan__Transaction_Time__c,
                                          loan__Principal__c,
                                          loan__Interest__c
                                          from loan__Loan_Payment_Transactions__r 
                                          where id =: DPD.loan__Loan_Payment_Transaction__c)                                         
                                          loan__Account__r.ID,
                                          (select id,name,loan__Due_Date__c  
                                           from loan__Dues_Details__r)
                                          loan__Account__r.Borrower_s_Last_Name__c,
                                          loan__Loan_Product_Name__c 
                                          from loan__Loan_Account__c];
    
     loan__Loan_Account__c loanAccount = LAList[0];
     
     payments = [select id,name,
                                          loan__Transaction_Date__c, 
                                          loan__Transaction_Time__c,
                                          loan__Principal__c,loan__Interest__c, 
                                          (select id,name,
                                            loan__Due__c  
                                            from loan__Due_Payments__r)
                                           
                                          from loan__Loan_Payment_Transaction__c 
                                          where id =: DPD.loan__Loan_Payment_Transaction__c];
                                          
     System.debug(logginglevel.error, 'loanAccount ::'+loanAccount + 'payments ::'+payments);
     
     RescheduleMigratedLoan a = new RescheduleMigratedLoan(loanAccount.id);
     a.rescheduleLoan();
      Test.stopTest();       
    }
    
    Testmethod static void method2(){
    
    Date lastUnpaidDueDate = Date.newinstance(2020,04,01);
    Date lastPaidDueDate = Date.newinstance(2020,03,01);
    List<loan__Loan_Payment_Transaction__c> payments = new List<loan__Loan_Payment_Transaction__c>();
    
        test.startTest();
    List<loan__Loan_Account__c> LAList = [SELECT ID,Name,loan__Pre_Bill_Days__c,
                                            loan__Principal_Remaining__c,
                                            loan__Principal_Paid__c,
                                            loan__Interest_Paid__c,  
                                          loan__Previous_Installment_Date__c,
                                          loan__Loan_Product_Name__r.name, 
                                          loan__Payment_Amount__c, 
                                          loan__Next_Installment_Date__c, 
                                          (select id,name,
                                          loan__Transaction_Date__c, 
                                          loan__Transaction_Time__c,
                                          loan__Principal__c,
                                          loan__Interest__c
                                          from loan__Loan_Payment_Transactions__r 
                                          where loan__Transaction_Amount__c = 400)                                         
                                          loan__Account__r.ID,
                                          (select id,name,loan__Due_Date__c  
                                           from loan__Dues_Details__r)
                                          loan__Account__r.Borrower_s_Last_Name__c,
                                          loan__Loan_Product_Name__c 
                                          from loan__Loan_Account__c];
    
     loan__Loan_Account__c loanAccount = LAList[0];
     payments = LAList[0].loan__Loan_Payment_Transactions__r;
                                          
     System.debug(logginglevel.error, 'loanAccount ::'+loanAccount + 'payments ::'+payments);
     
     RescheduleMigratedLoan a = new RescheduleMigratedLoan(loanAccount.id);
     a.rescheduleLoan();   
       Test.stopTest(); 
    }
    
    Testmethod static void method3(){
    
    //Date lastUnpaidDueDate = Date.newinstance(2020,04,01);
    //Date lastPaidDueDate = Date.newinstance(2020,03,01);
    Date lastUnpaidDueDate = null;
    Date lastPaidDueDate = null;
    List<loan__Loan_Payment_Transaction__c> payments = new List<loan__Loan_Payment_Transaction__c>();
    Test.startTest();
    List<loan__Loan_Account__c> LAList = [SELECT ID,Name,loan__Pre_Bill_Days__c,
                                            loan__Principal_Remaining__c,
                                            loan__Principal_Paid__c,
                                            loan__Interest_Paid__c,  
                                          loan__Previous_Installment_Date__c,
                                          loan__Loan_Product_Name__r.name, 
                                          loan__Payment_Amount__c, 
                                          loan__Next_Installment_Date__c, 
                                          (select id,name,
                                          loan__Transaction_Date__c, 
                                          loan__Transaction_Time__c,
                                          loan__Principal__c,
                                          loan__Interest__c
                                          from loan__Loan_Payment_Transactions__r 
                                          where loan__Transaction_Amount__c = 400)                                         
                                          loan__Account__r.ID,
                                          (select id,name,loan__Due_Date__c  
                                           from loan__Dues_Details__r)
                                          loan__Account__r.Borrower_s_Last_Name__c,
                                          loan__Loan_Product_Name__c 
                                          from loan__Loan_Account__c];
    
     loan__Loan_Account__c loanAccount = LAList[0];
     System.debug('loan__Next_Installment_Date__c='+LAList[0].loan__Next_Installment_Date__c);
     payments = LAList[0].loan__Loan_Payment_Transactions__r;
     System.debug('loan__Transaction_Date__c='+payments[0].loan__Transaction_Date__c);
     System.debug('loanAccount='+loanAccount);
                                          
     System.debug(logginglevel.error, 'loanAccount ::'+loanAccount + 'payments ::'+payments);
     
     RescheduleMigratedLoan a = new RescheduleMigratedLoan(loanAccount.id, lastUnpaidDueDate, lastPaidDueDate);
     a.rescheduleLoan();   
       Test.stopTest(); 
    }
    
        
    Testmethod static void method5(){
    
    Date lastUnpaidDueDate = Date.newinstance(2020,04,01);
    Date lastPaidDueDate = Date.newinstance(2020,03,01);
    List<loan__Loan_Payment_Transaction__c> payments = new List<loan__Loan_Payment_Transaction__c>();
    Test.startTest();
        List<loan__Loan_Account__c> LAList = [SELECT ID,Name,loan__Pre_Bill_Days__c,
                                            loan__Principal_Remaining__c,
                                            loan__Principal_Paid__c,
                                            loan__Interest_Paid__c,  
                                          loan__Previous_Installment_Date__c,
                                          loan__Loan_Product_Name__r.name, 
                                          loan__Payment_Amount__c, 
                                          loan__Next_Installment_Date__c, 
                                          (select id,name,
                                          loan__Transaction_Date__c, 
                                          loan__Transaction_Time__c,
                                          loan__Principal__c,
                                          loan__Interest__c
                                          from loan__Loan_Payment_Transactions__r 
                                          where loan__Transaction_Amount__c = 400)                                         
                                          loan__Account__r.ID,
                                          (select id,name,loan__Due_Date__c  
                                           from loan__Dues_Details__r)
                                          loan__Account__r.Borrower_s_Last_Name__c,
                                          loan__Loan_Product_Name__c 
                                          from loan__Loan_Account__c];
    
     loan__Loan_Account__c loanAccount = LAList[0];
     payments = LAList[0].loan__Loan_Payment_Transactions__r;
                                          
     System.debug(logginglevel.error, 'loanAccount ::'+loanAccount + 'payments ::'+payments);
     
     RescheduleMigratedLoan a = new RescheduleMigratedLoan(loanAccount.id);
     a.rescheduleLoan();   
        Test.stopTest();
    }
    
    Testmethod static void method4(){
    
    //Date lastUnpaidDueDate = Date.newinstance(0000,04,01);
    //Date lastPaidDueDate = Date.newinstance(2020,03,01);
    Boolean useCustomLogging = false;
    CL_Contract_Migration_Error_Log__c errorLogObject;
    Date lastUnpaidDueDate =  null;
    Date lastPaidDueDate = null;
    List<loan__Loan_Payment_Transaction__c> payments = new List<loan__Loan_Payment_Transaction__c>();
    Test.startTest();
    List<loan__Loan_Account__c> LAList = [SELECT ID,Name,loan__Pre_Bill_Days__c,
                                            loan__Principal_Remaining__c,
                                            loan__Principal_Paid__c,
                                            loan__Interest_Paid__c,  
                                          loan__Previous_Installment_Date__c,
                                          loan__Loan_Product_Name__r.name, 
                                          loan__Payment_Amount__c, 
                                          loan__Next_Installment_Date__c, 
                                          (select id,name,
                                          loan__Transaction_Date__c, 
                                          loan__Transaction_Time__c,
                                          loan__Principal__c,
                                          loan__Interest__c
                                          from loan__Loan_Payment_Transactions__r 
                                          where loan__Transaction_Amount__c = 400)                                         
                                          loan__Account__r.ID,
                                          (select id,name,loan__Due_Date__c  
                                           from loan__Dues_Details__r)
                                          loan__Account__r.Borrower_s_Last_Name__c,
                                          loan__Loan_Product_Name__c 
                                          from loan__Loan_Account__c];
     loan__Loan_Account__c loanAccount = LAList[0];
     payments = LAList[0].loan__Loan_Payment_Transactions__r;
                                          
     System.debug(logginglevel.error, 'loanAccount ::'+loanAccount + 'payments ::'+payments);
     
     RescheduleMigratedLoan a = new RescheduleMigratedLoan(loanAccount.id, errorLogObject, useCustomLogging);
     a.rescheduleLoan();   
     Test.stopTest();  
    }
    
}