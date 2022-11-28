/* ****************Modification History******************
 * Modified By        Date          JIRA number
 *1. Pallavi        2022/05/16      FUS-9598
 *2. Pallavi		2022/05/19		FUS-9666
 ******************Modification History******************/
global class E_Transfer_Actions {
        @AuraEnabled
 public static string geturl(string loanId,string templatename){
       string returnurl='';
        list<APXTConga4__Conga_Merge_Query__c> lstquerys=[select id,APXTConga4__Name__c from APXTConga4__Conga_Merge_Query__c ];
        map<string,id> mapqueryData=new map<String,id>();
        for(APXTConga4__Conga_Merge_Query__c query:lstquerys){
          mapqueryData.put(query.APXTConga4__Name__c,query.id);  
        }
         list<APXTConga4__Conga_Template__c> lstTemplates=[select id,APXTConga4__Name__c from APXTConga4__Conga_Template__c ];
        map<string,id> mapTemplateData=new map<String,id>();
        for(APXTConga4__Conga_Template__c template:lstTemplates){
          mapTemplateData.put(template.APXTConga4__Name__c,template.id);  
        }
     if(templatename=='PayOffQuote'){
         list<loan__Payoff_Quote__c> lstpay=[select id,Preferred_Launguage__c from loan__Payoff_Quote__c where id=:loanId];
         String templateid='';
         if(lstpay[0].Preferred_Launguage__c=='ENG'){
            templateid='PayOffQuoteEng'; 
         }else{
           templateid='PayOffQuoteFR';   
         }
      string strurl='/apex/APXTConga4__Conga_Composer?SolMgr=1';
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        string congaUrl=baseUrl+strurl+baseUrl+'&Id='+loanId+'&TemplateId='+mapTemplateData.get(templateid)+'&DefaultPDF=1&DS7=13';
        system.debug('congaurl is : '+congaUrl);
        returnurl=congaUrl;      
     }
     return returnurl; 
 }
      @AuraEnabled
    public static decimal getExcessRefundAmount(String loanid){
        list<loan__Loan_Account__c> lstacc=[select id,loan__Excess__c from loan__Loan_Account__c where id=:loanid];
        decimal excessAmount=lstacc[0].loan__Excess__c.setScale(2);
        return excessAmount;
        
    }
       @AuraEnabled
    public static string validateChargeForRefund(String loanid,string actiontype,id chargeid){
        list<loan__Charge__c> lstcharge=[select id,loan__Fee__r.name from loan__Charge__c where id=:chargeid and loan__Loan_Account__c=:loanid];
        if(actiontype=='Insurance refund' && lstcharge[0].loan__Fee__r.name!='Loan Protection Plan'){
            return 'For Insurance refund you can provide only charge with fee name Loan protection plan.';
        }else if(actiontype=='Credit Optimizer refund' && lstcharge[0].loan__Fee__r.name!='Credit Optimizer'){
            return 'For Credit Optimizer refund you can provide only charge with fee name Credit Optimizer.';
        }else if(actiontype=='Prepayment penalty' && lstcharge[0].loan__Fee__r.name!='Prepayment Penalty'){
            return 'For Prepayment Penalty refund you can provide only charge with fee name Prepayment Penalty.';
        }else if(actiontype=='Collateral Discharge fee' && lstcharge[0].loan__Fee__r.name!='Collateral Discharge Fee'){
            return 'For Collateral Discharge Fee refund you can provide only charge with fee name Collateral Discharge Fee.';
        }else if(actiontype=='Monthly processing fee' && lstcharge[0].loan__Fee__r.name!='Monthly Processing Fee'){
            return 'For Monthly Processing Fee refund you can provide only charge with fee name Monthly Processing Fee.';
        }
        return 'success';
        
        
    }
    
    
    @AuraEnabled
    public static string cancelbuttonForRefund(string refundId){
        string errormsg='';
        try{
            
            system.debug('id is--'+refundId);
            // system.debug('transferStatus is--'+transferStatus);
            loan.GlobalLoanUtilFacade loanFacade = new loan.GlobalLoanUtilFacade();
            DateTime currentSystemDate = loanFacade.getCurrentSystemDateTime(); 
            list<loan__Borrower_Refund_Transaction__c> lstRefund=[select id,
                                                                  E_Transfer_Transfer_Status__c,
                                                                  Payment_Mode_Name__c 
                                                                  from loan__Borrower_Refund_Transaction__c where id=:refundId];
            system.debug('lstRefund are '+lstRefund);
            loan__Borrower_Refund_Transaction__c refund=lstRefund[0];
            if(refund.Payment_Mode_Name__c!='E-Transfer'){
                errormsg='Only E-Transfer payment\'s can be cancelled.Aborting request..' ;
                return errormsg;
            }else if(refund.Payment_Mode_Name__c=='E-Transfer' && refund.Cancellation_Request_Status__c=='pending'){
                errormsg='E-Transfer cancellation has been requested already. Aborting request..';
                return errormsg;
            }else if(refund.Payment_Mode_Name__c=='E-Transfer' && refund.E_Transfer_Transfer_Status__c=='Cancelled'){
                errormsg='E-Transfer is already cancelled. Aborting request..';
                return errormsg;
            }
            if(refund.Payment_Mode_Name__c=='E-Transfer' && refund.E_Transfer_Transfer_Status__c=='Processed')
            {
                refund.id=refundId;
                refund.E_Transfer_Cancellation_Requested__c=true;
                refund.E_Transfer_Cancellation_Request_Date__c=currentSystemDate;
                refund.E_Transfer_Cancellation_Request_By__c=UserInfo.getUserId();
                refund.Cancellation_Request_Status__c='Pending';
                refund.loan__Sent_To_ACH__c=false;
                SecureDML.updateRecords(refund);
                //update refund;
                errormsg='E-Transfer is cancelled successfully.';
            }
            else{
                errormsg='Only E-Transfer\'s with transfer status as processed can be cancelled.Aborting request..';
            }
        }
        
        catch(Exception e){
            errormsg='Error Exception happend'+e.getMessage();
            return errormsg;
            // throw new AuraHandledException('Error Exception happend'+e.getMessage());           
            
        }
        return errormsg;
    }
    public static void isReversedForRefund(map<id,loan__Borrower_Refund_Transaction__c> oldMap,map<id,loan__Borrower_Refund_Transaction__c> newMap)
    {
        
        list<loan__Borrower_Refund_Transaction__c> lstRefundToupdate=new list<loan__Borrower_Refund_Transaction__c>();
        
        for(loan__Borrower_Refund_Transaction__c refund:newMap.values())
        {
            loan__Borrower_Refund_Transaction__c oldRefund=oldMap.get(refund.id);
            loan__Borrower_Refund_Transaction__c newRefund=new loan__Borrower_Refund_Transaction__c();
            if(oldRefund.loan__Reversed__c==False && refund.loan__Reversed__c==True && oldRefund.Payment_Mode_Name__c=='E-Transfer' && refund.Payment_Mode_Name__c=='E-Transfer'){
                newRefund.id=refund.id;
                newRefund.E_Transfer_Transfer_Status__c='Cancelled';
                if(refund.E_Transfer_Transfer_Status__c=='Pending'){                 
                    newRefund.E_Transfer_Cancelled_Reason__c='Stopped Prior File Generation';
                }else{
                    newRefund.E_Transfer_Cancelled_Reason__c='Stopped Post File Generation';
                }
                lstRefundToupdate.add(newRefund);
                
            }
        }
        
        SecureDML.updateRecords(lstRefundToupdate);
        //update lstRefundToupdate;
    }
    public static void updateETransferAmountForRefund(map<id,loan__Borrower_Refund_Transaction__c> maprefunds){
        
        
    }
    public static void generatePasswordforRefund(List<loan__Borrower_Refund_Transaction__c> refundList){
        List<ID> refundIdList = new List<Id>();
        for(loan__Borrower_Refund_Transaction__c refund : refundList){
            if(refund.Payment_Mode_Name__c=='E-Transfer'){
                refundIdList.add(refund.Id);
            }
        }
        if(!refundIdList.isEmpty()){
        ETransferPasswordGeneratorForRefund.generateETransferPassword(refundIdList);    
            ETransferSMSCallOutAdapterForRefund.sendETransferPasswordFuture(refundIdList);}
    }
    
    public static void validationsForRefund(list<loan__Borrower_Refund_Transaction__c> newRefundList){
        
        list<id> lstid=new list<id>();
        list<id> lstidcheque=new list<id>();
         loan.GlobalLoanUtilFacade loanFacade = new loan.GlobalLoanUtilFacade();
            DateTime currentSystemDate = loanFacade.getCurrentSystemDateTime(); 
            date currentSystemDate1=loanFacade.getCurrentSystemDate();
        list<loan__Borrower_Refund_Transaction__c> lstidchequerefund=new list<loan__Borrower_Refund_Transaction__c>();
        // list<E_Transfer__mdt> lstAmtCAP=[select id,MasterLabel,Amount__c from E_Transfer__mdt  where MasterLabel='E-Transfer Amount CAP'];
        // decimal AmountCAP=lstAmtCAP[0].Amount__c;
        for(loan__Borrower_Refund_Transaction__c refund:newRefundList){
            system.debug(newRefundList);
            if(refund.Payment_Mode_Name__c=='E-Transfer'){
                lstid.add(refund.loan__Loan_Account__c);
                
            }
            if(refund.Payment_Mode_Name__c=='Cheque'){
                lstidcheque.add(refund.loan__Loan_Account__c);
                lstidchequerefund.add(refund);
            }
        }
        User u = [select id,genesis__Current_Branch__c from user where id=:userinfo.getuserid() ];
        if(!lstidcheque.isEmpty()){
            updateMobileForChequeforRefund(lstidchequerefund,lstidcheque);  
        }
        if(!lstid.isEmpty()){
            map<id,loan__Loan_Account__c> mapcontracts=new map<id,loan__Loan_Account__c>([select id,name,
                                                                                          loan__Account__C  
                                                                                          from loan__Loan_Account__c where id in :lstid ]);
            list<id> lstaccids=new list<id>();
            for(loan__Loan_Account__c acc:mapcontracts.values()){
                lstaccids.add(acc.loan__Account__C);  
            }
            map<id,Account> mapAccount=new map<id,Account>([select id,name,(select id,province__c,email,Phone_Number_Validated__c,is_Email_Validated__c,MobilePhone,FirstName,LastName,clcommon__Current_State__c from contacts) from account where id in :lstaccids]);
            
            system.debug('map of loan accounts are '+mapcontracts);
            for(loan__Borrower_Refund_Transaction__c refund:newRefundList){
                loan__Loan_Account__c contract=mapcontracts.get(refund.loan__Loan_Account__c);
                system.debug('account is '+contract.loan__Account__C);
                Account acc=mapAccount.get(contract.loan__Account__C);
                
                refund.E_Transfer_Email__c=acc.contacts[0].Email;
                refund.E_Transfer_Mobile__c=acc.contacts[0].MobilePhone;
                refund.Is_Email_Validated__c=acc.contacts[0].is_Email_Validated__c;
                refund.Is_Mobile_Validated__c=acc.contacts[0].Phone_Number_Validated__c; 
                refund.E_Transfer_Transfer_Status__c='Pending';
                refund.E_Transfer_Created_Date__c=currentSystemDate1;
                if(acc.contacts[0].province__c!=CLS_ETransferIntegrationConstants.ProvinceName)
                {refund.Launguage_Preference__C=CLS_ETransferIntegrationConstants.E_Transfer_Launguage_EN;}
                else
                {refund.Launguage_Preference__C=CLS_ETransferIntegrationConstants.E_Transfer_Launguage_FR;}  
                refund.Customer_Name__c=acc.contacts[0].FirstName+' '+acc.contacts[0].LastName; 
                //refund.User_Branch__c=u.genesis__Current_Branch__c;
                if(refund.Service_Fees__c!=null){
                    refund.E_Transfer_Amount__c=refund.loan__Refund_Amount__c-refund.Service_Fees__c;
                }
                else
                {
                    refund.E_Transfer_Amount__c=refund.loan__Refund_Amount__c;  
                    
                }
                //}
            }
            
        }
    }
    
    @AuraEnabled
    public static string validationsForRefundAura(decimal amount,string loanid,string paymentModeId){
        //decimal amount=1000;
        string msg='Validation Successfull';
        system.debug('in apex class');
        system.Debug('loan id is'+loanid);
        list<id> lstid=new list<id>();
        list<loan__Payment_Mode__c> lstPMs=[select id,name from loan__Payment_Mode__c where id=:paymentModeId ];
        if(!lstPMs.isEmpty()){
            if(lstPMs[0].name=='E-Transfer'){
                list<E_Transfer__mdt> lstAmtCAP=[select id,MasterLabel,Amount__c from E_Transfer__mdt  where MasterLabel='E-Transfer Amount CAP'];
                decimal AmountCAP=lstAmtCAP[0].Amount__c;
                system.debug('amount cap is'+AmountCAP);
                User u = [select id,genesis__Current_Branch__c from user where id=:userinfo.getuserid()];
                
                list<loan__Loan_Account__c> contracts=[select id,name,loan__Account__C from loan__Loan_Account__c where id=:loanid ];
                system.debug('contract is '+contracts[0]);
                list<Account> lstacc=[select id,name,(select id,email,Phone_Number_Validated__c,is_Email_Validated__c,MobilePhone,FirstName,LastName,clcommon__Current_State__c from contacts) from account where id=:contracts[0].loan__Account__C ];
                system.debug('account is ' + lstacc[0]);
                if(!lstacc.isEmpty()){
                    Account acc=lstacc[0];
                    if(acc.contacts[0].Email=='' || acc.contacts[0].Email==null||acc.contacts[0].MobilePhone==null||acc.contacts[0].MobilePhone==''){
                        msg='Either Email/Phone is missing in Contact.Please correct before creating Refund transaction. '; 
                        return msg;
                    }
                    if(acc.contacts[0].is_Email_Validated__c==false){
                        msg='Email is not valid.Please validate email before creating Refund transaction.';
                        return msg;
                    }else if(acc.contacts[0].Phone_Number_Validated__c==false)
                    {
                        msg='Phone# is not valid.Please validate Phone# before creating Refund transaction.'; 
                        return msg;
                    }else if(amount>AmountCAP)
                    {
                        msg='Transaction Amount is not in range.The specified maximum limit for E-Transfer is '+String.valueof(AmountCAP); 
                        return msg;
                    }else{
                        msg='Validation Successfull';
                    }
                }
            }
        }
        return msg;    
        
    }
    
    @AuraEnabled
    public static string cancelbutton(string disbursalid){
        string msg='';
        try{
            system.debug('id is--'+disbursalid);
            // system.debug('transferStatus is--'+transferStatus);
            loan.GlobalLoanUtilFacade loanFacade = new loan.GlobalLoanUtilFacade();
            DateTime currentSystemDate = loanFacade.getCurrentSystemDateTime(); 
            list<loan__Loan_Disbursal_Transaction__c> lstLDTS=[select id,
                                                               E_Transfer_Transfer_Status__c,
                                                               Payment_Mode_Name__c 
                                                               from loan__Loan_Disbursal_Transaction__c where id=:disbursalid];
            if(lstLDTS[0].Payment_Mode_Name__c!='E-Transfer'){
                msg='Only E-Transfer payment\'s can be cancelled.Aborting request..';
                return msg;
            }
            system.debug('lstLDTS are '+lstLDTS);
            loan__Loan_Disbursal_Transaction__c ldt=lstLDTS[0];
            if(ldt.Payment_Mode_Name__c=='E-Transfer' && ldt.E_Transfer_Transfer_Status__c=='Processed')
            {
                ldt.id=disbursalid;
                ldt.E_Transfer_Cancellation_Requested__c=true;
                ldt.E_Transfer_Cancellation_Request_Date__c=currentSystemDate;
                ldt.E_Transfer_Cancellation_RequestBy__c=UserInfo.getUserId();
                ldt.Cancellation_Request_Status__c='Pending';
                SecureDML.updateRecords(ldt);
                //update ldt;
                msg='E-Transfer is Cancelled successfully';
                return msg;
            }
            else{
                msg='Only E-Transfer\'s with transfer status as processed can be cancelled.Aborting request..';
                return msg;
            }
        }
        
        catch(Exception e){
            msg='Error Exception happend'+e.getMessage();
            return msg;
            //throw new AuraHandledException('Error Exception happend'+e.getMessage());           
            
        }
        
    }
    public static void isReversed(map<id,loan__Loan_Disbursal_Transaction__c> oldMap,map<id,loan__Loan_Disbursal_Transaction__c> newMap)
    {
        list<loan__Loan_Disbursal_Transaction__c> lstLDTToupdate=new list<loan__Loan_Disbursal_Transaction__c>();
        
        for(loan__Loan_Disbursal_Transaction__c LDT:newMap.values())
        {
            loan__Loan_Disbursal_Transaction__c oldLDT=oldMap.get(LDT.id);
            loan__Loan_Disbursal_Transaction__c newLDT=new loan__Loan_Disbursal_Transaction__c();
            if(oldLDT.loan__Reversed__c==False && LDT.loan__Reversed__c==True && oldLDT.Payment_Mode_Name__c=='E-Transfer' && LDT.Payment_Mode_Name__c=='E-Transfer'){
                newLDT.id=LDT.id;
                newLDT.E_Transfer_Transfer_Status__c='Cancelled';
                if(LDT.E_Transfer_Transfer_Status__c=='Pending'){                 
                    newLDT.E_Transfer_Cancelled_Reason__c='Stopped Prior File Generation';
                }else{
                    newLDT.E_Transfer_Cancelled_Reason__c='Stopped Post File Generation';
                }
                lstLDTToupdate.add(newLDT);
                
            }
        }
        SecureDML.updateRecords(lstLDTToupdate);
        //update lstLDTToupdate;
    }
    public static void updateETransferAmount(map<id,loan__Loan_Disbursal_Transaction__c> mapLDTs){
        list<loan__Loan_Disbursal_Transaction__c> lstlddtToUpdate=new list<loan__Loan_Disbursal_Transaction__c>();
        list<id> lstid=new list<id>(mapLDTs.keyset());
        map<id,loan__Loan_Disbursal_Transaction__c> mapdistributions=new map<id,loan__Loan_Disbursal_Transaction__c>([select id,loan__Disbursed_Amt__c,(select id,loan__Distribution_Amount__c from loan__Disbursal_Transaction_Distribution__r where loan__Distribution_Type__c='Disbursement') from loan__Loan_Disbursal_Transaction__c where id in:lstid]);
        list<loan__Loan_Disbursal_Transaction__c> lstLDTToupdate=new list<loan__Loan_Disbursal_Transaction__c>();
        for(loan__Loan_Disbursal_Transaction__c ldt:mapLDTs.values()){
            if(ldt.Payment_Mode_Name__c=='E-Transfer'){
                loan__Loan_Disbursal_Transaction__c newLDT=new loan__Loan_Disbursal_Transaction__c();
                loan__Loan_Disbursal_Transaction__c distributions=mapdistributions.get(ldt.id);
                newLDT.id=ldt.id;
                if(!distributions.loan__Disbursal_Transaction_Distribution__r.isEmpty()){
                    newLDT.E_Transfer_Amount__c=distributions.loan__Disbursal_Transaction_Distribution__r[0].loan__Distribution_Amount__c;
                }else{
                    newLDT.E_Transfer_Amount__c=ldt.loan__Disbursed_Amt__c;  
                }
                // ldt.E_Transfer_Amount__c=ldt.loan__Disbursed_Amt__c-distributions[0].loan__Distribution_Amount__c;
                lstlddtToUpdate.add(newLDT);
            }
        }
        if(!lstlddtToUpdate.isEmpty())
        {
            SecureDML.updateRecords(lstlddtToUpdate);
            //update lstlddtToUpdate;
        }
    }
    public static void validations(list<loan__Loan_Disbursal_Transaction__c> newLDTList){
        list<id> lstid=new list<id>();
        list<id> lstchequid=new list<id>();
        list<loan__Loan_Disbursal_Transaction__c> lstchequldt=new list<loan__Loan_Disbursal_Transaction__c>();
        list<E_Transfer__mdt> lstAmtCAP=[select id,MasterLabel,Amount__c from E_Transfer__mdt  where MasterLabel='E-Transfer Amount CAP'];
        decimal AmountCAP=lstAmtCAP[0].Amount__c;
        for(loan__Loan_Disbursal_Transaction__c ldt:newLDTList){
            system.debug(newLDTList);
            if(ldt.Payment_Mode_Name__c=='Cheque'){
                lstchequid.add(ldt.loan__Loan_Account__c);
                lstchequldt.add(ldt);
            }
            if(ldt.Payment_Mode_Name__c=='E-Transfer'){
                lstid.add(ldt.loan__Loan_Account__c);
                system.debug('contract is '+ldt.loan__Loan_Account__c);
                //system.debug('Account is '+ldt.loan__Loan_Account__r.loan__Account__C);
                //system.debug('contact is '+ldt.loan__Loan_Account__r.loan__Account__r.Customer__c);
            }   
        }
        if(!lstchequid.isEmpty()){
            updateMobileForCheque(lstchequldt,lstchequid);  
        }
        if(!lstid.isEmpty()){
            User u = [select id,genesis__Current_Branch__c from user where id=:userinfo.getuserid() ];
            map<id,loan__Loan_Account__c> mapcontracts=new map<id,loan__Loan_Account__c>([select id,name,
                                                                                          loan__Account__C   
                                                                                          from loan__Loan_Account__c where id in :lstid ]);
            list<id> lstaccids=new list<id>();
            for(loan__Loan_Account__c acc:mapcontracts.values()){
                lstaccids.add(acc.loan__Account__C);  
            }
            map<id,Account> mapAccount=new map<id,Account>([select id,name,(select id,province__c,email,Phone_Number_Validated__c,is_Email_Validated__c,MobilePhone,FirstName,LastName,clcommon__Current_State__c from contacts) from account where id in :lstaccids]);
            
            system.debug('map of loan accounts are '+mapcontracts);
            for(loan__Loan_Disbursal_Transaction__c ldt:newLDTList){
                loan__Loan_Account__c contract=mapcontracts.get(ldt.loan__Loan_Account__c);
                system.debug('account is '+contract.loan__Account__C);
                Account acc=mapAccount.get(contract.loan__Account__C);
                if(acc.contacts[0].Email=='' || acc.contacts[0].Email==null||acc.contacts[0].MobilePhone==null||acc.contacts[0].MobilePhone==''){
                    ldt.adderror('Either Email/Phone is missing in Contact.');  
                }
                if(acc.contacts[0].is_Email_Validated__c==false){
                    ldt.adderror('Email is not valid.Please validate email before creating loan disbursal transaction.');
                }else if(acc.contacts[0].Phone_Number_Validated__c==false)
                {
                    ldt.adderror('Phone# is not valid.Please validate Phone# before creating loan disbursal transaction.');  
                }else if(ldt.loan__Disbursed_Amt__c>AmountCAP)
                {
                    ldt.adderror('Transaction Amount is not in range.The specified maximum limit for E-Transfer is '+String.valueof(AmountCAP));   
                }
                else{
                    ldt.E_Transfer_Email__c=acc.contacts[0].Email;
                    ldt.E_Transfer_Mobile__c=acc.contacts[0].MobilePhone;
                    ldt.Is_Email_Validated__c=acc.contacts[0].is_Email_Validated__c;
                    ldt.Is_Mobile_Validated__c=acc.contacts[0].Phone_Number_Validated__c; 
                    ldt.E_Transfer_Transfer_Status__c='Pending';  
                    if(acc.contacts[0].province__c!=CLS_ETransferIntegrationConstants.ProvinceName)
                    {ldt.Launguage_Preference__C=CLS_ETransferIntegrationConstants.E_Transfer_Launguage_EN;}
                    else
                    {ldt.Launguage_Preference__C=CLS_ETransferIntegrationConstants.E_Transfer_Launguage_FR;}  
                    ldt.Customer_Name__c=acc.contacts[0].FirstName+' '+acc.contacts[0].LastName; 
                    ldt.User_Branch__c=u.genesis__Current_Branch__c;
                    
                }
            }
        }
    } 
    @AuraEnabled
    public static Map<String,String> getCashPaymentMode(String loanContractId) {
        try{
            Map<String,String> paymentModeIdByName = new Map<String,String>();
           
            list<RecordType> rectype=[SELECT Id,Name FROM RecordType WHERE SobjectType='loan__Other_Transaction__c' and name='Refund Record Type'];
            paymentModeIdByName.put('recordTypeId',rectype[0].id);
            
            for(loan__Payment_Mode__c paymentMode: [Select Id,name from loan__Payment_Mode__c where Name ='Cash' OR Name = 'Cheque' OR 
                                                    Name ='E-Transfer' OR Name='Prepaid Card' OR Name='Credit Card'
                                                   OR Name='Insurance Waive' OR Name='Creditoptimizer Waive' OR Name='Insurance Claim Payment'
                                                   OR Name='EFT' ]){
                paymentModeIdByName.put(paymentMode.Name,paymentMode.Id);
            }
            // Get mobile/Email
            loan__Loan_Account__c loanContractRec=[select id,name,loan__Account__c from loan__Loan_Account__c where id=:loanContractId ];
            
            map<id,Account> mapAccount=new map<id,Account>([select id,name,(select id,province__c,email,Phone_Number_Validated__c,is_Email_Validated__c,MobilePhone,FirstName,LastName,clcommon__Current_State__c from contacts) from account where id=:loanContractRec.loan__Account__c]);
            Account acc=mapAccount.get(loanContractRec.loan__Account__c);
            paymentModeIdByName.put('Mobile',acc.contacts[0].MobilePhone);
            paymentModeIdByName.put('Email',acc.contacts[0].Email);
            
            
            return paymentModeIdByName;
        }catch(Exception e){
            return null;
        }
        
    }
    public static void updateMobileForCheque(list<loan__Loan_Disbursal_Transaction__c> ltds,list<id> lstid){
        map<id,loan__Loan_Account__c> mapcontracts=new map<id,loan__Loan_Account__c>([select id,name,
                                                                                      loan__Account__C   
                                                                                      from loan__Loan_Account__c where id in :lstid ]);
        list<id> lstaccids=new list<id>();
        for(loan__Loan_Account__c acc:mapcontracts.values()){
            lstaccids.add(acc.loan__Account__C);  
        }
        map<id,Account> mapAccount=new map<id,Account>([select id,name,(select id,province__c,email,Phone_Number_Validated__c,is_Email_Validated__c,MobilePhone,FirstName,LastName,clcommon__Current_State__c from contacts) from account where id in :lstaccids]);
        
        system.debug('map of loan accounts are '+mapcontracts);
        for(loan__Loan_Disbursal_Transaction__c ldt:ltds){
            loan__Loan_Account__c contract=mapcontracts.get(ldt.loan__Loan_Account__c);
            system.debug('account is '+contract.loan__Account__C);
            Account acc=mapAccount.get(contract.loan__Account__C);
            ldt.E_Transfer_Mobile__c=acc.contacts[0].MobilePhone;
        }
    }
    public static void updateMobileForChequeforRefund(list<loan__Borrower_Refund_Transaction__c> ltds,list<id> lstid){
        map<id,loan__Loan_Account__c> mapcontracts=new map<id,loan__Loan_Account__c>([select id,name,
                                                                                      loan__Account__C   
                                                                                      from loan__Loan_Account__c where id in :lstid ]);
        list<id> lstaccids=new list<id>();
        for(loan__Loan_Account__c acc:mapcontracts.values()){
            lstaccids.add(acc.loan__Account__C);  
        }
        map<id,Account> mapAccount=new map<id,Account>([select id,name,(select id,province__c,email,Phone_Number_Validated__c,is_Email_Validated__c,MobilePhone,FirstName,LastName,clcommon__Current_State__c from contacts) from account where id in :lstaccids]);
        
        system.debug('map of loan accounts are '+mapcontracts);
        for(loan__Borrower_Refund_Transaction__c ldt:ltds){
            loan__Loan_Account__c contract=mapcontracts.get(ldt.loan__Loan_Account__c);
            system.debug('account is '+contract.loan__Account__C);
            Account acc=mapAccount.get(contract.loan__Account__C);
            ldt.E_Transfer_Mobile__c=acc.contacts[0].MobilePhone;
        }
    }
    @AuraEnabled
    public static Map<String,String> getBaseAndTaxAmounts(string paymentmode,string loanid,decimal amount) {
        string message='';
        decimal baseAmount=0.0;
     decimal taxAmount=0.0;
        decimal taxpercentage=0.0;
     map<string,string> returnmsg=new map<string,string>();
         /* list<loan__Payment_Mode__c> paymentmodes=[select id,name from loan__Payment_Mode__c where (name='creditoptimizer Waive' 
                                               or name='Insurance Waive') and id=:paymentmode];*/
      if(paymentmode=='Insurance refund'){
 list<loan__Loan_Account__c> lstacc=[select id,Province__c,loan__Account__r.Customer_on_Reserves__c from loan__Loan_Account__c where id=:loanid];
            if(lstacc[0].loan__Account__r.Customer_on_Reserves__c=='No' || lstacc[0].loan__Account__r.Customer_on_Reserves__c==null ){
             list<LPP_Tax_Rate__c> taxrates=[select id,Tax__c from LPP_Tax_Rate__c where name=:lstacc[0].Province__c];
              taxpercentage=taxrates[0].Tax__c/100;
             
            baseAmount=(amount/(1+taxpercentage)).setscale(2);
             taxAmount= amount-baseAmount;  
         
            }
          else{
            taxAmount=0.0;
            baseAmount=amount;  
          }
          returnmsg.put('BaseAmount',string.valueof(baseAmount));
                 returnmsg.put('TaxAmount',string.valueof(taxAmount));
             
         }
        else if(paymentmode=='Credit Optimizer refund'){
        
              list<loan__Periodic_Fee_Setup__c> lstperiodic=[select id,name,Current_Base_Amount__c,Tax__c,Current_Tax_Amount__c,Fee_Name__c,
                                                             loan__Lending_Account__r.loan__Account__r.Customer_on_Reserves__c,Base_Amount__c,Tax_Amount__c
                                                        from loan__Periodic_Fee_Setup__c where Fee_Name__c='Credit Optimizer'
                                                            and loan__Lending_Account__c=:loanid ];
             
              if(!lstperiodic.isEmpty() && lstperiodic[0].Tax__c!=null && (lstperiodic[0].loan__Lending_Account__r.loan__Account__r.Customer_on_Reserves__c=='No'||lstperiodic[0].loan__Lending_Account__r.loan__Account__r.Customer_on_Reserves__c==null)){
                  taxpercentage=lstperiodic[0].Tax__c/100;
             
            baseAmount=(amount/(1+taxpercentage)).setscale(2);
             taxAmount= amount-baseAmount; 
                  returnmsg.put('BaseAmount',string.valueof(baseAmount));
                 returnmsg.put('TaxAmount',string.valueof(taxAmount));
              }
             else{
                 returnmsg.put('BaseAmount',string.valueof(amount));
                 returnmsg.put('TaxAmount',string.valueof('0.0'));
             }
         }   
        
        return returnmsg;
    }
    /*FUS-9598*/
    @AuraEnabled
    public static Map<String,String> getBaseAndTaxAmountsfromCharge(id chargeID){
        map<string,string> returnmsg=new map<string,string>();
        loan__Charge__c charge = [select id,Paid_Tax_Amount__c,Paid_Subscription_Amount__c,loan__Paid_Amount__c from loan__Charge__c where id =: chargeID];
        returnmsg.put('BaseAmount',string.valueof(charge.Paid_Subscription_Amount__c));	//FUS-9666
        returnmsg.put('TaxAmount',string.valueof(charge.Paid_Tax_Amount__c));
        returnmsg.put('OriginalAmount',string.valueof(charge.loan__Paid_Amount__c));
        return returnmsg;
    }
    /*FUS-9598*/
}