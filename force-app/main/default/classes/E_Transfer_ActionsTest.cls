@istest
public class E_Transfer_ActionsTest {
 @TestSetup
    static void createSeedData(){
     
          loan.TestHelper.createSeedDataForTesting();
          Account acc = new Account() ;
          acc.Name = 'Test Acc';
          acc.ownerID = UserInfo.getUserId() ;
          SecureDML.insertRecords(acc);
        contact con1=new contact();
        con1.LastName='abc';
        con1.FirstName='efg';
        con1.AccountId=acc.id;
        con1.Email='abc@gmail.com';
        con1.MobilePhone='13212143213';
        con1.Is_Email_Validated__c=true;
        con1.Phone_Number_Validated__c=true;
        SecureDML.insertRecords(con1);
          Account accountTest = [Select id, name from Account];
                    
          loan__Loan_Purpose__c dummyLoanPurpose = loan.TestHelper.createLoanPurpose();
          
          loan__Office_Name__c dummyOffice = loan.testHelper.createOffice('dummyOffice');
          
          loan__Client__c dummyClient = loan.testhelper.createClient ( dummyOffice ) ;
     
          loan__MF_Account__c mfAccount = loan.TestHelper.createMFAccount ( 'XXXAccountForTest', 'Type' ) ;
          loan__Currency__c curr = loan.TestHelper.createCurrency() ;

          List<loan__Fee__c> feeList = new List<loan__Fee__c>() ;
          loan__Fee__c dummyFee = new loan__Fee__c() ;
          dummyFee.name = 'Credit Monitoring';
          dummyFee.loan__State__c = 'Active';
          dummyFee.loan__Time_of_charge__c = 'Time of Charge';
          dummyFee.loan__Include_In_Dues__c = true;
          dummyFee.loan__Fee_Calculation_Method__c = 'FLAT';
          dummyFee.loan__Amount__c = 100;
          dummyFee.loan__Periodic_Fee_Amount_Type__c = 'Amount';
         
          feeList.add ( dummyFee ) ;
          
          loan__Fee__c dummyLPPFee = new loan__Fee__c() ;
          dummyLPPFee.name = 'Loan Protection Plan';
          dummyLPPFee.loan__State__c = 'Active';
          dummyLPPFee.loan__Time_of_charge__c = 'Periodic Fees';
          dummyLPPFee.loan__Include_In_Dues__c = true;
          dummyLPPFee.loan__Fee_Calculation_Method__c = 'Fixed';
          dummyLPPFee.loan__Amount__c = 25;
          dummyLPPFee.loan__Periodic_Fee_Amount_Type__c = 'Per Period Amount';
          dummyLPPFee.loan__Periodic_Charge_Start_Basis__c = 'First Payment Date';
          feeList.add ( dummyLPPFee) ;
          
          loan__Fee__c dummyFeePPP = new loan__Fee__c() ;
          dummyFeePPP.name = 'Payment Protection Plan';
          dummyFeePPP.loan__State__c = 'Active';
          dummyFeePPP.loan__Time_of_charge__c = 'Time of Charge';
          dummyFeePPP.loan__Include_In_Dues__c = true;
          dummyFeePPP.loan__Fee_Calculation_Method__c = 'FLAT';
          dummyFeePPP.loan__Amount__c = 100;
          dummyFeePPP.loan__Periodic_Fee_Amount_Type__c = 'Amount';
      
          feeList.add ( dummyFeePPP ) ;
          SecureDML.insertRecords(feeList);

 

          loan__Fee_Set__c dummyFeeSet = loan.TestHelper.createFeeSet() ;
          
          loan__Fee_Junction__c dummyFeeJunction = loan.TestHelper.createFeeJunction ( dummyLPPFee, dummyFeeSet ) ;
          
          loan__Payment_Mode__c paymentMode = new loan__Payment_Mode__c ( name = 'E-Transfer' ) ;
          SecureDML.insertRecords(paymentMode);
           
          loan__Loan_Product__c loanProduct  = new loan__Loan_Product__c() ;  
          loanProduct.Name = 'Test';
          loanProduct.loan__Interest_Calculation_Method__c = 'FLAT';
          loanProduct.loan__Frequency_of_Loan_Payment__c = 'Monthly';
          loanProduct.loan__Loan_Product_Type__c = 'Loan';
          loanProduct.loan__Time_Counting_Method__c = 'Month And Days';
          loanProduct.loan__Status__c = 'Active';
          loanProduct.loan__Max_Loan_Amount__c = 100000;
          loanProduct.loan__Fee_Set__c = dummyFeeSet.id;
          loanProduct.loan__Min_Interest_Rate__c = 5;
          loanProduct.loan__Max_Interest_Rate__c = 20;
          loanProduct.loan__Default_Interest_Rate__c = 10;
              
          SecureDML.insertRecords(loanProduct);

          loan__loan_Account__c loanAccount = loan.TestHelper.createLoanAccountForAccountObj ( loanProduct , accountTest , dummyFeeSet,  dummyLoanPurpose,  dummyOffice ) ;
         
   
      loan__Payment_Mode__c payment = [ SELECT 
                                         ID , 
                                         Name
                                      FROM 
                                         loan__Payment_Mode__c where Name='E-Transfer'
                                      LIMIT 1] ;

          Loan__Loan_Disbursal_Transaction__c disTxn = new Loan__Loan_Disbursal_Transaction__c ( loan__Loan_Account__c = loanAccount.Id, loan__Disbursed_Amt__c = loanAccount.loan__loan_Amount__c, loan__Mode_of_Payment__c = payment.id ) ;
          loan.LoanDisbursalActionAPI api = new loan.LoanDisbursalActionAPI ( disTxn ) ;
          loanAccount = api.disburseLoanAccount (); 
          
        
          loan__Fee_Payment__c feePayment = new loan__Fee_Payment__c() ;
       
          feePayment.loan__Transaction_Date__c = System.today() ;
        
          feePayment.loan__Transaction_Amount__c = 1000;
          SecureDML.insertRecords(feePayment);


          loan__Other_Transaction__c otherTxn = new loan__Other_Transaction__c();
          otherTxn.loan__Txn_Date__c = date.today();
          otherTxn.loan__Loan_Account__c = loanAccount.id;
          otherTxn.loan__Transaction_Type__c = 'Reschedule' ;
          SecureDML.insertRecords(otherTxn);
          
            Date nextMonthDate =  new loan.GlobalLoanUtilFacade().getCurrentSystemDate().addMonths(1);
            Date back75Years = nextMonthDate.addYears(-75);
            Contact con = new Contact();
          con.AccountId = accountTest.id;
          con.Birthdate = back75Years;
          con.ownerID = UserInfo.getUserId() ;
          con.Email = 'tarang.bhargava@getafixtechnologies.com';
          con.MobilePhone = '(234) 234-2422';
          con.Phone = '(234) 234-2420';
          //con.Name = 'Aaa';
          con.FirstName = 'aaa';
          con.LastName = 'bbb';
          con.ints__Middle_Name__c = 'Aaa Bbb';
          //con.Mother_s_Maiden_Name__c = 'Ccc';
          con.collect__Source_Name__c = 'Test Data';
          con.Title = 'Mr';
         // SecureDML.insertRecords(con);
                    
          loanAccount.loan__Pmt_Amt_Cur__c = 100;
          loanAccount.loan__Payment_Amount__c  =100;
          loanAccount.loan__Loan_Status__c = 'Active - Bad Standing' ;
          loanAccount.loan__loan_Amount__c = 20000;
          //loanAccount.ECT_Approved_Program__c = 'Term Extension';
          loanAccount.loan__Frequency_of_Loan_Payment__c = 'Monthly'; 
          loanAccount.loan__Number_of_Installments__c = 24;
          //loanAccount.loan__Application_Date__c = Date.newInstance(2017, 12, 4);
          loanAccount.loan__Application_Date__c = new loan.GlobalLoanUtilFacade().getCurrentSystemDate();
          loanAccount.loan__Expected_Disbursal_Date__c= new loan.GlobalLoanUtilFacade().getCurrentSystemDate();
          loanAccount.loan__Interest_Type__c = 'Fixed';
          loanAccount.loan__Loan_Amount__c = 20000; 
          loanAccount.loan__loan_status__c = 'Active - Bad Standing';
          loanAccount.loan__Expected_Repayment_Start_Date__c = new loan.GlobalLoanUtilFacade().getCurrentSystemDate().addMonths(1);
          loanAccount.loan__Contract_Type__c = 'New';
          loanAccount.loan__Interest_Type__c = 'Fixed';
          //loanAccount.Number_of_ECT_s_Applied__c = 1; 
          loanAccount.loan__First_Installment_Date__c =  new loan.GlobalLoanUtilFacade().getCurrentSystemDate();
          loanAccount.loan__Maturity_Date_Current__c =  new loan.GlobalLoanUtilFacade().getCurrentSystemDate();
          loanAccount.loan__Last_Installment_Date__c =  new loan.GlobalLoanUtilFacade().getCurrentSystemDate();
          SecureDML.updateRecords(loanAccount);
        loan__Borrower_Refund_Transaction__c refund=new loan__Borrower_Refund_Transaction__c();
        refund.loan__Mode_of_Payment__c=paymentMode.id;
        refund.loan__Loan_Account__c=loanAccount.id;
        SecureDML.insertRecords(refund);
 
    }
       static testMethod void testUpdatingNextRecurDate() {
    
        Test.startTest();
   		loan__Borrower_Refund_Transaction__c refund=[select id from loan__Borrower_Refund_Transaction__c];
           refund.E_Transfer_Transfer_Status__c='Processed';
           SecureDML.updateRecords(refund);
           E_Transfer_Actions.cancelbuttonForRefund(refund.id);
           Loan__Loan_Disbursal_Transaction__c LDT=[select id,loan__Mode_of_Payment__c,loan__Mode_of_Payment__r.Name from Loan__Loan_Disbursal_Transaction__c];
           system.debug('payment mode is'+LDT.loan__Mode_of_Payment__r.Name);
           E_Transfer_Actions.cancelbutton(LDT.id);
           loan__Payment_Mode__c payment = [ SELECT 
                                         ID , 
                                         Name
                                      FROM 
                                         loan__Payment_Mode__c where Name='E-Transfer'
                                      LIMIT 1] ;
           LDT.loan__Reversed__c=true;
           LDT.E_Transfer_Transfer_Status__c='Processed';          
           SecureDML.updateRecords(LDT);
            E_Transfer_Actions.cancelbutton(LDT.id);
           test.stopTest();
       }
}