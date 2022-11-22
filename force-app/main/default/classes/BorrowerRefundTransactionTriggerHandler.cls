public class BorrowerRefundTransactionTriggerHandler {
    public static BorrowerRefundTransactionTriggerHandler instance = null;
    private BorrowerRefundTransactionTriggerHandler(){}


    public static BorrowerRefundTransactionTriggerHandler getInstance(){
        if(instance == null)
            instance = new BorrowerRefundTransactionTriggerHandler();
        return instance;
    }
    public void validateProfileForPaymentMode(list<loan__Borrower_Refund_Transaction__c> lstbrt){
    /*
      List<String> restrictedmodes =new list<string>();
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
         list<Loan_Profile_Validation__mdt> lstmdt=[select id,Restricted_PickList_For_Payment_Modes__c 
                                                         from Loan_Profile_Validation__mdt where Profile_Name__c=:PROFILE[0].Name];
             if(!lstmdt.isEmpty()){
            restrictedmodes = lstmdt[0].Restricted_PickList_For_Payment_Modes__c.split(':');         
            }
        for(loan__Borrower_Refund_Transaction__c brt:lstbrt){
         for(string s :restrictedmodes){
                if( brt.Payment_Mode_Name__c!=null && s.substring(1,s.length()-1).trim().equalsIgnoreCase(brt.Payment_Mode_Name__c.trim())){
                   brt.addError('User with profile '+PROFILE[0].Name+' is not allowed to post the payment using '+brt.Payment_Mode_Name__c+' payment mode'); 
                }
            }
        } */
        
        //FUS-6565 
        //Customer should not be able to refund to other bank accounts
         list<id> rtaids=new list<id>();
     list<id> accountids=new list<id>();
         for(loan__Borrower_Refund_Transaction__c brt:lstbrt)
         {
          system.debug('brt is'+brt);  
           
            if(brt.loan__Repayment_Transaction_Reversal__c!=null){
               rtaids.add(brt.loan__Repayment_Transaction_Reversal__c); 
            }
           }
        system.debug('rtaids is'+rtaids);
        list<loan__Repayment_Transaction_Adjustment__c> lstRTA=[select id,loan__Loan_Payment_Transaction__r.loan__Loan_Account__r.loan__Account__c
                                                                 from loan__Repayment_Transaction_Adjustment__c where id in :rtaids ];
        map<id,id> mapRTAAccids=new map<id,id>();
        for(loan__Repayment_Transaction_Adjustment__c RTA: lstRTA){
          accountids.add(RTA.loan__Loan_Payment_Transaction__r.loan__Loan_Account__r.loan__Account__c);
            mapRTAAccids.put(RTA.id,RTA.loan__Loan_Payment_Transaction__r.loan__Loan_Account__r.loan__Account__c);
        }
        system.debug('accountids is'+accountids);
        list<loan__Bank_Account__c> listBankAccounts=[select id,loan__Account__c from loan__Bank_Account__c where loan__Active__c=true and loan__Account__c in :accountids ];
       system.debug('listBankAccounts are '+listBankAccounts);
        list<id> banklst=new list<id>();
        map<id,list<id>> mapAccBankids=new map<id,list<id>>();
        for(loan__Bank_Account__c bank:listBankAccounts){
            system.debug('map is '+mapAccBankids);
        if(mapAccBankids.get(bank.loan__Account__c)!=null){
            system.debug('inside loop');
            banklst=new list<id>();
        banklst=mapAccBankids.get(bank.loan__Account__c); 
            banklst.add(bank.id);
            system.debug('banklst is '+banklst);
        }else{
            banklst=new list<id>{bank.id};  
        }
        
            system.debug('bank id is'+banklst);
            mapAccBankids.put(bank.loan__Account__c,banklst);
            system.debug('mapAccBankids is '+mapAccBankids);
         // banklst.clear();  
        }
        for(loan__Borrower_Refund_Transaction__c brt:lstbrt){ 
            if(brt.loan__Repayment_Transaction_Reversal__c!=null && brt.loan__Refund_To_Bank_Account__c!=null){
                id Accountid=mapRTAAccids.get(brt.loan__Repayment_Transaction_Reversal__c);
                list<id> bankaccid=mapAccBankids.get(Accountid);
                if(!bankaccid.contains(brt.loan__Refund_To_Bank_Account__c)){
                    brt.addError('Bank account is not related to CL Contract Account Or Bank Account is Inactive.');
                }
            }
        }
        
    }
    /*
    public void beforeInsertHandler(Map<Id,loan__Borrower_Refund_Transaction__c> lptNewMap,Map<Id,loan__Borrower_Refund_Transaction__c> lptOldMap,List<loan__Borrower_Refund_Transaction__c> newList){
        //beforeInsertProfilevalidation(lptNewMap,lptOldMap,newList);
    }
    
    public void beforeInsertProfilevalidation(Map<Id,loan__Borrower_Refund_Transaction__c> lptNewMap,Map<Id,loan__Borrower_Refund_Transaction__c> lptOldMap,List<loan__Borrower_Refund_Transaction__c> newList){
        List<String> allPaymentModes    = new List<String>();
        List<String> allCLContracts     = new List<String>();
        Id currentProfileId             = UserInfo.getProfileId();
        
        String profileName              = [Select Name from Profile where Id =:currentProfileId Limit 1].Name;
        
        for(loan__Borrower_Refund_Transaction__c brtRec:newList){
            allPaymentModes.add(brtRec.loan__Mode_of_Payment__c);
            //allCLContracts.add(lptRec.loan__Loan_Account__c);
        } 
        Map<Id,loan__Payment_Mode__c> allPaymentModeById  = new Map<Id,loan__Payment_Mode__c>([Select Id,Name from loan__Payment_Mode__c where ID IN :allPaymentModes]);
        
        //Map<Id,loan__Loan_Account__c> allCLContractById  = new Map<Id,loan__Loan_Account__c>([Select Id,Name,loan__Loan_Status__c,Sold__c,Litigation__c from loan__Loan_Account__c where ID IN :allCLContracts]);
        
        if(profileName!= CLL_ProfileConstant.AUDIT_PROFILE || profileName!=CLL_ProfileConstant.SYS_ADMIN_PROFILE){
            // Only System Admin And Audit can create a LPT with a given unique payment mode
            
            for(loan__Borrower_Refund_Transaction__c brtRec:newList){
                if(allPaymentModeById.containsKey(brtRec.loan__Mode_of_Payment__c) && allPaymentModeById.get(brtRec.loan__Mode_of_Payment__c).Name==CLL_ProfileConstant.OFFICE_CHEQUE_PAYMENT){
                    brtRec.addError('You can not post a loan payment transaction with '+CLL_ProfileConstant.OFFICE_CHEQUE_PAYMENT+' Payment Mode');
                }
                
            }
            
        }
    }
     public void beforeUpdateHandler(Map<Id,loan__Borrower_Refund_Transaction__c> lptNewMap,Map<Id,loan__Borrower_Refund_Transaction__c> lptOldMap,List<loan__Borrower_Refund_Transaction__c> newList){
        beforeUpdateProfileValidation(lptNewMap,lptOldMap);
    }
    
    public void beforeUpdateProfileValidation(Map<Id,loan__Borrower_Refund_Transaction__c> lptNewMap,Map<Id,loan__Borrower_Refund_Transaction__c> lptOldMap){
        
    }*/
    public void updateReversalDateOnOLT(Map<Id,loan__Borrower_Refund_Transaction__c> brtNewMap,Map<Id,loan__Borrower_Refund_Transaction__c> brtOldMap,List<loan__Borrower_Refund_Transaction__c> newList){
        list<loan__Other_Transaction__c> lstOltToupdate=new list<loan__Other_Transaction__c>();
        System.debug('in after update');
        for(loan__Borrower_Refund_Transaction__c refund:brtNewMap.values())
        {
            if(brtOldMap.get(refund.id).loan__Reversed__c==False && refund.loan__Reversed__c==True && refund.loan__Excess_Repayment_Transaction__c != null){
                lstOltToupdate.add(new loan__Other_Transaction__c(Id=refund.loan__Excess_Repayment_Transaction__c, Transaction_Reversal_Date__c=refund.Transaction_Reversal_Date__c,loan__Reversed__c=true));
            }
        }
        //update lstOltToupdate;
        SecureDML.updateRecords(lstOltToupdate);
    }

}