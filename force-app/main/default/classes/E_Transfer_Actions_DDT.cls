public class E_Transfer_Actions_DDT {
    public static void validateProfileForPaymentMode(list<loan__Disbursal_Txn_Distribution__c> lstddt){
      List<String> restrictedmodes =new list<string>();
     List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId()  LIMIT 1];
       list<Loan_Profile_Validation__mdt> lstmdt=[select id,Restricted_PickList_For_Payment_Modes__c 
                                                        from Loan_Profile_Validation__mdt where Profile_Name__c=:PROFILE[0].Name ];
            if(!lstmdt.isEmpty()){
           restrictedmodes = lstmdt[0].Restricted_PickList_For_Payment_Modes__c.split(':');         
           }
       for(loan__Disbursal_Txn_Distribution__c ddt:lstddt){
        for(string s :restrictedmodes){
               if( s.substring(1,s.length()-1).trim().equalsIgnoreCase(ddt.Payment_Mode_Name__c.trim())){
                  ddt.addError('User with profile '+PROFILE[0].Name+' is not allowed to post the payment using '+ddt.Payment_Mode_Name__c+' payment mode'); 
               }
           }   
       }   
   }
@AuraEnabled
   public static string cancelbutton(string dtdid){
       string msg='';
       try{
           system.debug('id is--'+dtdid);
           // system.debug('transferStatus is--'+transferStatus);
           loan.GlobalLoanUtilFacade loanFacade = new loan.GlobalLoanUtilFacade();
           DateTime currentSystemDate = loanFacade.getCurrentSystemDateTime();  
           list<loan__Disbursal_Txn_Distribution__c> lstLDTS=[select id,
                                                              E_Transfer_Transfer_Status__c,
                                                              Cancellation_Request_Status__c,
                                                              Payment_Mode_Name__c 
                                                              from loan__Disbursal_Txn_Distribution__c where id=:dtdid];
           if(lstLDTS[0].Payment_Mode_Name__c!='E-Transfer'){
               msg='Only E-Transfer payment\'s can be cancelled. Aborting request..';
               return msg;
           }else if(lstLDTS[0].Payment_Mode_Name__c=='E-Transfer' && lstLDTS[0].Cancellation_Request_Status__c=='pending'){
               msg='E-Transfer cancellation has been requested already. Aborting request..';
               return msg;
           }else if(lstLDTS[0].Payment_Mode_Name__c=='E-Transfer' && lstLDTS[0].E_Transfer_Transfer_Status__c=='Cancelled'){
               msg='E-Transfer is already cancelled. Aborting request..';
               return msg;
           }
           system.debug('lstLDTS are '+lstLDTS);
           loan__Disbursal_Txn_Distribution__c ldt=lstLDTS[0];
           if(ldt.Payment_Mode_Name__c=='E-Transfer' && ldt.E_Transfer_Transfer_Status__c=='Processed')
           {
                   ldt.id=dtdid;
                   ldt.E_Transfer_Cancellation_Requested__c=true;
                   ldt.E_Transfer_Cancellation_Request_Date__c=currentSystemDate;
                   ldt.E_Transfer_Cancellation_RequestBy__c=UserInfo.getUserId();
                   ldt.Cancellation_Request_Status__c='Pending';
               ldt.loan__Sent_To_ACH__c=false;
               SecureDML.updateRecords(ldt);
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
   public static void isReversed(map<id,loan__Disbursal_Txn_Distribution__c> oldMap,map<id,loan__Disbursal_Txn_Distribution__c> newMap)
   {
       list<loan__Disbursal_Txn_Distribution__c> lstDDTToupdate=new list<loan__Disbursal_Txn_Distribution__c>();
       
       for(loan__Disbursal_Txn_Distribution__c DDT:newMap.values())
       {
           loan__Disbursal_Txn_Distribution__c oldDDT=oldMap.get(DDT.id);
           loan__Disbursal_Txn_Distribution__c newDDT=new loan__Disbursal_Txn_Distribution__c();
           if(oldDDT.loan__Reversed__c==False && DDT.loan__Reversed__c==True && oldDDT.Payment_Mode_Name__c=='E-Transfer' && DDT.Payment_Mode_Name__c=='E-Transfer'){
               newDDT.id=DDT.id;
               newDDT.E_Transfer_Transfer_Status__c='Cancelled';
               if(DDT.E_Transfer_Transfer_Status__c=='Pending'){                 
                   newDDT.E_Transfer_Cancelled_Reason__c='Stopped Prior File Generation';
               }else{
                   newDDT.E_Transfer_Cancelled_Reason__c='Stopped Post File Generation';
               }
               lstDDTToupdate.add(newDDT);
               
           }
       }
       SecureDML.updateRecords(lstDDTToupdate);
   }
   /*
   public static void updateETransferAmount(map<id,loan__Disbursal_Txn_Distribution__c> mapLDTs){
       list<loan__Disbursal_Txn_Distribution__c> lstlddtToUpdate=new list<loan__Disbursal_Txn_Distribution__c>();
       list<id> lstid=new list<id>(mapLDTs.keyset());
       map<id,loan__Disbursal_Txn_Distribution__c> mapdistributions=new map<id,loan__Disbursal_Txn_Distribution__c>([select id,loan__Disbursed_Amt__c,(select id,loan__Distribution_Amount__c from loan__Disbursal_Transaction_Distribution__r where loan__Distribution_Type__c='Disbursement') from loan__Loan_Disbursal_Transaction__c where id in:lstid]);
       list<loan__Disbursal_Txn_Distribution__c> lstLDTToupdate=new list<loan__Disbursal_Txn_Distribution__c>();
       for(loan__Disbursal_Txn_Distribution__c ldt:mapLDTs.values()){
           if(ldt.Payment_Mode_Name__c=='E-Transfer'){
               loan__Disbursal_Txn_Distribution__c newLDT=new loan__Disbursal_Txn_Distribution__c();
               loan__Disbursal_Txn_Distribution__c distributions=mapdistributions.get(ldt.id);
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
       }
   }
*/
   public static void validations(list<loan__Disbursal_Txn_Distribution__c> newLDTList){
       list<id> lstid=new list<id>();
           list<id> lstchequid=new list<id>();
         loan.GlobalLoanUtilFacade loanFacade = new loan.GlobalLoanUtilFacade();
           DateTime currentSystemDate = loanFacade.getCurrentSystemDateTime(); 
           date currentSystemDate1=loanFacade.getCurrentSystemDate();
        list<loan__Disbursal_Txn_Distribution__c> lstchequldt=new list<loan__Disbursal_Txn_Distribution__c>();
       list<E_Transfer__mdt> lstAmtCAP=[select id,MasterLabel,Amount__c from E_Transfer__mdt  where MasterLabel='E-Transfer Amount CAP'];
       decimal AmountCAP=lstAmtCAP[0].Amount__c;
       for(loan__Disbursal_Txn_Distribution__c ldt:newLDTList){
           system.debug(newLDTList);
           if(ldt.Payment_Mode_Name__c=='Cheque'){
              lstchequid.add(ldt.loan__Loan_Disbursal_Transaction__C);
               lstchequldt.add(ldt);
           }
           if(ldt.Payment_Mode_Name__c=='E-Transfer'){
               lstid.add(ldt.loan__Loan_Disbursal_Transaction__C);
            }  
           system.debug('lstid are '+lstid);
       }
       if(!lstchequid.isEmpty()){
         updateMobileForCheque(lstchequldt,lstchequid);  
       }
       if(!lstid.isEmpty()){
           User u = [select id,genesis__Current_Branch__c from user where id=:userinfo.getuserid()];
           map<id,loan__Loan_Disbursal_Transaction__c> mapcontracts=new map<id,loan__Loan_Disbursal_Transaction__c>([select id,name,
                                                                                         loan__Loan_Account__r.loan__Account__C   
                                                                                         from loan__Loan_Disbursal_Transaction__c where id in :lstid ]);
          system.debug('map of LDT is '+mapcontracts);
           list<id> lstaccids=new list<id>();
           for(loan__Loan_Disbursal_Transaction__c acc:mapcontracts.values()){
               lstaccids.add(acc.loan__Loan_Account__r.loan__Account__C);  
           }
           system.debug(' account ids are '+lstaccids);
           map<id,Account> mapAccount=new map<id,Account>([select id,name,(select id,province__c,email,Phone_Number_Validated__c,is_Email_Validated__c,MobilePhone,FirstName,LastName,clcommon__Current_State__c from contacts) from account where id in :lstaccids]);
           
           system.debug('map of loan accounts are '+mapAccount);
           for(loan__Disbursal_Txn_Distribution__c ldt:newLDTList){
               if(ldt.Payment_Mode_Name__c=='E-Transfer'){
               system.debug('ldt is '+ldt.loan__Loan_Disbursal_Transaction__c);
               loan__Loan_Disbursal_Transaction__c contract=mapcontracts.get(ldt.loan__Loan_Disbursal_Transaction__c);
               system.debug('account is '+contract.loan__Loan_Account__r.loan__Account__C);
               Account acc=mapAccount.get(contract.loan__Loan_Account__r.loan__Account__C);
               if(acc.contacts[0].Email=='' || acc.contacts[0].Email==null||acc.contacts[0].MobilePhone==null||acc.contacts[0].MobilePhone==''){
                   ldt.adderror('Either Email/Phone is missing in Contact.');  
               }
               if(acc.contacts[0].is_Email_Validated__c==false){
                   ldt.adderror('Email is not valid.Please validate email before creating/updating transaction.');
               }else if(acc.contacts[0].Phone_Number_Validated__c==false)
               {
                   ldt.adderror('Phone# is not valid.Please validate Phone# before creating/updating transaction.');  
               }else if(ldt.Net_Amount__c>AmountCAP)
               {
                   ldt.adderror('Transaction Amount is not in range.The specified maximum limit for E-Transfer is '+String.valueof(AmountCAP) + ' and entered amount is '+ldt.Net_Amount__c);   
               }
               else{
                   ldt.E_Transfer_Email__c=acc.contacts[0].Email;
                   ldt.E_Transfer_Amount__c=ldt.Net_Amount__c;
                   ldt.E_Transfer_Created_Date__c=currentSystemDate1;
                  // ldt.Loan_Name__c=contract.loan__Loan_Account__c;
                   ldt.E_Transfer_Mobile__c=acc.contacts[0].MobilePhone;
                   ldt.Is_Email_Validated__c=acc.contacts[0].is_Email_Validated__c;
                   ldt.Is_Mobile_Validated__c=acc.contacts[0].Phone_Number_Validated__c; 
                   ldt.E_Transfer_Transfer_Status__c='Pending';  
                   if(acc.contacts[0].province__c!=CLS_ETransferIntegrationConstants.ProvinceName)
                   {ldt.Launguage_Preference__C=CLS_ETransferIntegrationConstants.E_Transfer_Launguage_EN;}
                   else
                   {ldt.Launguage_Preference__C=CLS_ETransferIntegrationConstants.E_Transfer_Launguage_FR;}  
                   ldt.Customer_Name__c=acc.contacts[0].FirstName+' '+acc.contacts[0].LastName; 
                  // ldt.User_Branch__c=u.genesis__Current_Branch__c;
                   
               }
           }
           }
       }
   } 
   @AuraEnabled
   public static Map<String,String> getCashPaymentMode(String loanContractId) {
       try{
           Map<String,String> paymentModeIdByName = new Map<String,String>();
           
           for(loan__Payment_Mode__c paymentMode: [Select Id,name from loan__Payment_Mode__c where Name ='Cash' OR Name = 'Cheque' OR Name ='E-Transfer' OR Name='Prepaid Card' ]){
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
   public static void updateMobileForCheque(list<loan__Disbursal_Txn_Distribution__c> ltds,list<id> lstid){
        map<id,loan__Loan_Disbursal_Transaction__c> mapcontracts=new map<id,loan__Loan_Disbursal_Transaction__c>([select id,name,
                                                                                         loan__Loan_Account__r.loan__Account__C   
                                                                                         from loan__Loan_Disbursal_Transaction__c where id in :lstid ]);
          system.debug('map of LDT is '+mapcontracts);
           list<id> lstaccids=new list<id>();
           for(loan__Loan_Disbursal_Transaction__c acc:mapcontracts.values()){
               lstaccids.add(acc.loan__Loan_Account__r.loan__Account__C);  
           }
           system.debug(' account ids are '+lstaccids);
           map<id,Account> mapAccount=new map<id,Account>([select id,name,(select id,province__c,email,Phone_Number_Validated__c,is_Email_Validated__c,MobilePhone,FirstName,LastName,clcommon__Current_State__c from contacts) from account where id in :lstaccids]);
           
           system.debug('map of loan accounts are '+mapcontracts);
           for(loan__Disbursal_Txn_Distribution__c ldt:ltds){
               loan__Loan_Disbursal_Transaction__c contract=mapcontracts.get(ldt.loan__Loan_Disbursal_Transaction__c);
               system.debug('account is '+contract.loan__Loan_Account__r.loan__Account__C);
               Account acc=mapAccount.get(contract.loan__Loan_Account__r.loan__Account__C);
               //loan__Loan_Account__c contract=mapcontracts.get(ldt.loan__Loan_Disbursal_Transaction__r.loan__Loan_Account__c);
               //system.debug('account is '+contract.loan__Account__C);
              // Account acc=mapAccount.get(contract.loan__Account__C);
               ldt.E_Transfer_Mobile__c=acc.contacts[0].MobilePhone;
           }
   }
  
}