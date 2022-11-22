public class BluePayPaymentReturnHandler {

    private List<SObject> payments;
    private Map<ID,String> returnCodeMap;

    //ND-1460
    private Set<String> closeReturnCodes; 

    //Key - Payment Mode Id, Value = Set of return codes related to specific action.
    private Map<ID,Set<String>> lptStopAchReturnCodeStore;
    private Map<ID,Set<String>> lptApplyNsfReturnCodeStore;

    public Boolean outOfOrderReversal;

    public BluePayPaymentReturnHandler(List<SObject> payments,Map<ID,String> returnCodeMap) {
        
        this.payments = this.filterRecentPayments(payments);
        this.returnCodeMap = returnCodeMap;
        this.outOfOrderReversal = false;
        if(this.returnCodeMap  == null){ 
            this.returnCodeMap  = new Map<ID,String>();
			for(sobject obj : payments){
                String code = (String)obj.get('Return_Description__c');
                if(code != null){
					this.returnCodeMap.put(obj.Id, code);
                }
			}
        }
        initializeCollections();
    }
    
    public List<SObject> filterRecentPayments(List<SObject> payments){
        Set<Id> loanIds = new Set<Id>();
        List<SObject> toBeReturned = new List<SObject>();
        Map<Id,loan__Loan_Payment_Transaction__C> lptMap = new Map<Id,loan__Loan_Payment_Transaction__C>();
        Map<Id,Id> loanIdVsRecentPaymentId = new Map<Id,Id>(); 
       
        for(loan__Loan_Payment_Transaction__C obj : (List<loan__Loan_Payment_Transaction__C>)payments){
            loanIds.add(obj.loan__Loan_Account__c);
            lptMap.put(obj.Id,obj);
        }
       
        for(loan__Loan_Payment_Transaction__C lpt : [Select Id,loan__loan_Account__c 
                                                    from loan__Loan_Payment_Transaction__c 
                                                     where loan__loan_Account__c in :loanIds 
                                                     Order by Name DESC]){
                      
            if(!loanIdVsRecentPaymentId.containsKey(lpt.loan__loan_Account__c)){
                loanIdVsRecentPaymentId.put(lpt.loan__loan_Account__c,lpt.Id);
                if(lptMap.containsKey(lpt.Id)){
                    toBeReturned.add(lptMap.get(lpt.Id));
                }
            }  
            
            if(loanIdVsRecentPaymentId.size() == loanIds.size()){
                break; 
            }
        }
        
        return toBeReturned;
    }
  
    //ND-1460
    private void initializeCollections() {
        //LPT Return Code Stores
        lptStopAchReturnCodeStore = new Map<ID,Set<String>>();
        lptApplyNsfReturnCodeStore = new Map<ID,Set<String>>();

        List<loan__Automated_Payment_Configuration__c> apcConfigs = [SELECT ID,
                                                                      Name,
                                                                      loan__Payment_Mode__c,
                                                                      loan__Event__c,
                                                                      loan__Active__c,
                                                                      (SELECT Id,Name,
                                                                              loan__Return_Action__c,
                                                                              loan__Return_Codes__c
                                                                       FROM loan__ACH_Return_Action_Configs__r)
                                                                FROM loan__Automated_Payment_Configuration__c
                                                                WHERE loan__Active__c = true
                                                                    AND loan__Event__c IN (:loan.LoanConstants.LOAN_PAYMENT) 
                                                               ];
        if (apcConfigs != null && !apcConfigs.isEmpty()) {
            List<loan__ACH_Return_Action_Config__c> returnConfigs;
            Set<String> stopAchRetCodes;
            Set<String> applyNsfRetCodes;

            /*
             * Assumption: Combination of APC Event & Payment mode will be unique.
             * For ex: 'ACH' named payment mode can be assigned to 'Loan Payment' event only once.
             */
            for(loan__Automated_Payment_Configuration__c config : apcConfigs) {
                returnConfigs = config.loan__ACH_Return_Action_Configs__r;

                if (returnConfigs != null && !returnConfigs.isEmpty()) {
                    for(loan__ACH_Return_Action_Config__c retConfig : returnConfigs) {
                        //If Event is Loan Payment, add to lpt maps
                        if (config.loan__Event__c == loan.LoanConstants.LOAN_PAYMENT) {

                            if (retConfig.loan__Return_Action__c == loan.LoanConstants.STOP_ACH_ACTION) {
                                //avoid npe.
                                if (!String.isBlank(retConfig.loan__Return_Codes__c)) {
                                    stopAchRetCodes = new set<String>((retConfig.loan__Return_Codes__c).toLowerCase().split(';'));
                                    lptStopAchReturnCodeStore.put(config.loan__Payment_Mode__c,stopAchRetCodes);
                                }
                            }
                            else if (retConfig.loan__Return_Action__c == loan.LoanConstants.APPLY_NSF_ACTION) {
                                //avoid npe.
                                if (!String.isBlank(retConfig.loan__Return_Codes__c)) {
                                    applyNsfRetCodes = new set<String>((retConfig.loan__Return_Codes__c).toLowerCase().split(';'));
                                    lptApplyNsfReturnCodeStore.put(config.loan__Payment_Mode__c,applyNsfRetCodes);
                                }
                            }
                        }
                    }//end FOR - retConfig
                }
            }//End FOR - config
        }
    }

    public void processReturns() {
        if (payments[0] instanceof loan__Loan_Payment_Transaction__c) {
            processLoanPayments();
        }
    }

    private void processLoanPayments() {
       
        List<loan__Loan_Payment_Transaction__c> reverseAnyApplyNSF = new List<loan__Loan_Payment_Transaction__c>();
        List<loan__Loan_Account__c> loansForClearedPmt = new List<loan__Loan_Account__c>();    
        List<loan__Loan_Account__c> loansForUnclearedPmt = new List<loan__Loan_Account__c>();     
        List<loan__Loan_Payment_Transaction__c> reverseLPTS = new List<loan__Loan_Payment_Transaction__c>();
        Map<Id, loan__Automated_Payment_Setup__c> apsToBeUpdated = new Map<Id, loan__Automated_Payment_Setup__c>();
        Date currentSystemDate = BatchUtils.getRootBranch().loan__Current_System_Date__c;
        System.debug('currentSystemDate : '+currentSystemDate);
        for(SObject retPayment : payments) {
            loan__Loan_Payment_Transaction__c payment = (loan__Loan_Payment_Transaction__c) retPayment;
            //Retry ACH Payment
            /*
             * Update rejection date on LPT
             * Check if APS has retry enabled and return code is present in "Return codes for Retry" on APS
             * If yes, check which attempt was this and if we still need to attempt i.e.
             * APS.Number_of_Retry_Attempts__c < LPT.Retry_Attempt_Number__c
             * then stamp Retry_On__c on LPT according to Retry_Attempt_Interval__c on APS 
             */
            payment.loan__Rejection_Date__c = currentSystemDate;
            boolean applyNSF = false;
           
            if (payment.loan__Automated_Payment_Setup__c != null
                && returnCodeMap.containsKey(payment.Id)) {
                //added to avoid null pointer at any point of time
                String returnCode = returnCodeMap.get(payment.Id).toLowerCase();
                System.debug(LoggingLevel.ERROR, 'payment.Id : ' + payment.Id + ' returnCode : ' + returnCode);
                /*
                 * ND-1460 fix
                 */
                //get stop ach return codes for payment mode of LPT
                Set<String> stopAchReturnCodes = lptStopAchReturnCodeStore.get(payment.loan__Automated_Payment_Setup__r.loan__Payment_Mode__c);

                //Stop ACH if return code matches
                if (stopAchReturnCodes != null && stopAchReturnCodes.contains(returnCode)) {
                    System.debug(LoggingLEvel.ERROR,' De-activating APS ');
                    payment.loan__Automated_Payment_Setup__r.loan__Active__c = false;
                    loan__Automated_Payment_Setup__c aps = new loan__Automated_Payment_Setup__c(Id = payment.loan__Automated_Payment_Setup__c, loan__Active__c = false);
                    apsToBeUpdated.put(aps.Id, aps);
                }

                //Apply NSF if NSF return code is received.
                Set<String> applynsfReturnCodes = lptApplyNsfReturnCodeStore.get(payment.loan__Automated_Payment_Setup__r.loan__Payment_Mode__c);
                if (applynsfReturnCodes !=null && applynsfReturnCodes.contains(returnCode)) {
                    System.debug(LoggingLEvel.ERROR,' Applying NSF ');
                    applyNSF = true;
                }

                //Retry Action 
                //ND-2674 : If the APS corresponding to LPT is deactivated, The below logic should work
                // removed one condition : payment.Automated_Payment_Setup__r.Active__c == true
                Set<String> retryReturnCodes;
                if (payment.loan__Automated_Payment_Setup__r.loan__Return_Codes_for_Retry__c != null
                    && payment.loan__Automated_Payment_Setup__r.loan__Retry__c != null
                    && payment.loan__Automated_Payment_Setup__r.loan__Retry__c.equalsIgnoreCase(loan.LoanConstants.RETRY_ENABLED)) {

                    //Use case: When Retry module is enabled. NSF will be applied only on said number of retry attempts
                    //depending on whether LPT return code is part of NSF return code set or not

                    retryReturnCodes = new Set<String>(payment.loan__Automated_Payment_Setup__r.loan__Return_Codes_for_Retry__c
                                                .toLowerCase()
                                                .split(';'));
                    
                    //ND-2266 - Check if LPT Return code is part of Retry Return Code set, If it is update Next Retry Date and APS.
                    if (retryReturnCodes.contains(returnCode)) {
                        if (payment.loan__Retry_Attempt_Number__c == null) {
                            payment.loan__Retry_Attempt_Number__c = 0;
                        }
                        //Check if we have sufficient no of retry attempts
                        if (payment.loan__Retry_Attempt_Number__c < payment.loan__Automated_Payment_Setup__r.loan__Number_of_Retry_Attempts__c) {
                            payment.loan__Retry_On__c = currentSystemDate.addDays(Integer.valueOf(payment.loan__Automated_Payment_Setup__r.loan__Retry_Attempt_Interval__c));
                            loan__Automated_Payment_Setup__c aps = new loan__Automated_Payment_Setup__c(Id = payment.loan__Automated_Payment_Setup__c, loan__Pending_Retry__c = true);
                            apsToBeUpdated.put(aps.Id, aps);
                        }
                    }
                    
                    /*
                    * ND-2266 - Apply NSF on given number of attempt only if LPT Return code is part of NSF Return Codes.  
                    *           If 'Apply_NSF_on_Attempt__c' is set as null (which should not be the case), system will keep earlier decision to apply nsf as it is.        
                    *          
                    * [To Do] - Ideally, We should first check if LPT Return Code is part of NSF return code config, only after that we should calculate
                    *           current payment attempt. If LPT return code is not part of NSF return code, system should not apply an NSF even if current retry attempt 
                    *           is eligible to apply an NSF.
                    *           
                    * Note    - not changing code as explained above at this point to keep delta between PATCHes minimal
                    */
                    if (payment.loan__Automated_Payment_Setup__r.loan__Apply_NSF_on_Attempt__c != null) {    
                        Set<String> NSFOnAttempts = new Set<String>(payment.loan__Automated_Payment_Setup__r.loan__Apply_NSF_on_Attempt__c.split(';'));
                        String attempt = payment.loan__Retry_Attempt_Number__c == null ? 
                                                    '' : ('' + Integer.valueOf(payment.loan__Retry_Attempt_Number__c));
                        System.debug(LoggingLevel.ERROR, 'attempt : ' + attempt);
                        System.debug(LoggingLevel.ERROR, 'NSFOnAttempts : ' + NSFOnAttempts); 
                                            
                        if ((NSFOnAttempts.contains(attempt) || String.isBlank(attempt))
                            && applynsfReturnCodes !=null
                            && applynsfReturnCodes.contains(returnCode)) {
                            applyNSF = true;
                        }
                        else {
                            applyNSF = false;
                        }
                    }//end Apply NSF on attempt IF.
                    
                }//end RETRY IF
            }
            else {
                //if APS is not present on LPT then we will continue with regular strategy of applying NSF
                //this is the oldest behaviour where NSF is applied if it is defined in fee set 
                applyNSF = true; 
            }

           if (payment.loan__Reversal_Reason__c != null && payment.loan__Reversal_Reason__c == 'DECLINE') { 
                //payment.loan__Reversal_Reason__c = null;//returnCodeMap.get(payment.Id);
                reverseAnyApplyNSF.add(payment);
               
                if (applyNSF) {
                    loansForClearedPmt.add(payment.loan__Loan_Account__r);   
                }  
                
            }
            else {  
                /*payment.loan__Rejection_Reason__c = returnCodeMap.get(payment.Id);
                payment.loan__Rejected__c = true;*/
                reverseLPTS.add(payment);
                if (applyNSF) {
                    loansForUnclearedPmt.add(payment.loan__Loan_Account__r);
                }
            }
          
        
        }
        //Setting a save Point
        Savepoint sp = Database.setSavepoint();
        try{
            if (apsToBeUpdated.size() > 0) {
                
				Set<Id> apsIds = new Set<Id>();
                for(loan__Automated_Payment_Setup__c aps : apsToBeUpdated.values()){
                    if(!aps.loan__Active__c){
                    	apsIds.add(aps.Id);
                    }
                }
                SecureDML.updateRecords(apsToBeUpdated.values());
                if(apsIds.size() > 0){
                    set<id> bankIds = new Set<Id>();
                    for(loan__Automated_Payment_Setup__c aps : [Select loan__bank_Account__C from loan__Automated_Payment_Setup__c where Id in :apsIds ]){
                        bankIds.add(aps.loan__bank_Account__C);
                    } 
                    List<loan__Bank_Account__c> banks = [Select id,loan__Active__C from loan__Bank_Account__c where Id in :bankIds];
                    for(loan__Bank_Account__c bank : banks){
                        bank.loan__active__C = false;
                    }
                    SecureDML.updateRecords(banks);
                }
            }
          
            if (reverseAnyApplyNSF.size() > 0) {
                ACHReturnPaymentDynamicProcessor achReturnProcessorObj= new ACHReturnPaymentDynamicProcessor(reverseAnyApplyNSF, loansForClearedPmt);
                achReturnProcessorObj.outOfOrderReversal = this.outOfOrderReversal;
                achReturnProcessorObj.reversePayments();
                achReturnProcessorObj.processNSF();
            }
            
            if (reverseLPTS.size() > 0) {
                ACHReturnPaymentDynamicProcessor achReturnProcessorObjforLoan= new ACHReturnPaymentDynamicProcessor(reverseLPTS, loansForUnclearedPmt);
                achReturnProcessorObjforLoan.outOfOrderReversal = this.outOfOrderReversal;
                achReturnProcessorObjforLoan.reversePayments();
            }
          
        }catch(Exception e){
            Database.rollback(sp);
            System.debug(LoggingLevel.ERROR,'Error while processing LPT Return/reject action with NSF : '+e.getMessage());
            System.debug(LoggingLevel.ERROR,'Error while processing LPT Return/reject action with NSF : '+e.getStackTraceString());
        }
    }


}