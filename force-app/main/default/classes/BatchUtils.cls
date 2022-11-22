global class BatchUtils {
    
    private static User loggedInUser = null;
    public static loan__Office_Name__c loggedInBranch = null;
    private static ID rootBranchRecordTypeId = null;
    private static loan__Office_Name__c rootBranch = null;
    
    global static ID getRootBranchRecordTypeID() {
        if (rootBranchRecordTypeId != null) {
            return rootBranchRecordTypeId;
        }
        System.debug(LoggingLevel.ERROR, 'BranchName:' + loan.CustomSettingsUtil.getNS()+'Office_Name__c');
        rootBranchRecordTypeId = [SELECT ID FROM RecordType WHERE Name='Root Branch'
                                    AND DeveloperName='Root_Branch' and SObjectType = :loan.CustomSettingsUtil.getNS()+'Office_Name__c'  LIMIT 1 ].Id;
        System.debug('BranchUtilRootRecordtype:' + rootBranchRecordTypeId);
        return rootBranchRecordTypeId;
    }
    
    global static loan__Office_Name__c getRootBranch() {
        if (rootBranch == null) {
            rootBranch = [SELECT loan__Current_System_Date__c
                           FROM loan__Office_Name__c
                           WHERE RecordTypeID=:getRootBranchRecordTypeId()  LIMIT 1 ];
        }
        return rootBranch;
    }
    
     global static String getLoanFieldsForLPT() {
        return 'loan__Loan_Account__r.loan__Fee_Set__c,'+
               'loan__Loan_Account__r.loan__Total_Due_Charges__c,'+
               'loan__Loan_Account__r.Id,'+
               'loan__Loan_Account__r.Name,'+
               'loan__Loan_Account__r.loan__Loan_Amount__c,'+
               'loan__Loan_Account__r.loan__Fees_Remaining__c,'+
               'loan__Loan_Account__r.loan__Contact__c,'+
               'loan__Loan_Account__r.loan__Account__c,'+
               'loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__General_Rounding_Mode__c, '+
               'loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__Digits_After_Decimals__c, ' +
               'loan__Loan_Account__r.loan__Last_Transaction_Timestamp__c, '+
               'loan__Loan_Account__r.loan__Last_Transaction_Type__c, '+
               'loan__Loan_Account__r.loan__Last_Transaction_Id__c, '+
               'loan__Loan_Account__r.loan__Pay_Off_Amount_As_Of_Today__c';
    }
    
     global static String getLoanPaymentTxnFields() {
        return  'Id, ' +
                'Name, ' +
                'loan__Additional_Interest__c, '+
                'loan__Loan_Account__r.Name, '+
                'loan__Cash_Receipt_Application__c, '+
                'loan__Deposit__c, ' +
                'loan__Early_Total_Repayment_Of_The_Loan__c, ' +
                'loan__Fees__c, ' +
                'loan__Interest__c, ' +
                'loan__IOA__c, ' +
                'loan__Principal__c, ' +
                'loan__Excess__c, ' +
                'loan__Cleared__c, ' +
                'loan__Loan_Account__r.loan__active_investor__c, ' +
                'loan__Loan_Account__r.Id, '+
                'loan__Loan_Account__r.loan__Product_Type__c, '+
                'loan__Waived__c, ' +
                'loan__Payment_Application_Mode__c, '+
                'loan__Reversed__c, ' +
                'loan__Rebate_Payment__c, ' +
                'loan__Transaction_Amount__c, ' +
                'loan__Transaction_Date__c, ' +
                'loan__Transaction_Time__c, ' +
                'loan__Loan_Payment_Spread__c, ' +
                'loan__Manual_Payment__c, ' +
                'loan__Out_of_Order_Status__c, ' +
                'loan__Out_of_Order_Payment__c, ' +
                'loan__Payment_Mode__c, ' +
                'loan__Payment_Mode__r.Name, ' +
                'loan__Payment_Type__c, ' +
                'loan__Rejection_Reason__c, '+
                'loan__Retry_On__c, '+
                'loan__Rejected__c, ' +
                'loan__Rejection_Date__c, '+
                'loan__Reschedule_Threshold_Crossed__c, ' +
                'loan__Receipt_Date__c, ' +
                 'loan__Retry_Attempt_Number__c, '+
                 'loan__Reversal_Reason__c, '+
                'CreatedDate, ' +
                'loan__Dependent_Payment_Transaction__c, ' +
                'loan__Closure_Tolerance_Payment__c, ' +
                'loan__Loan_Account__c, ' +
                'loan__Backdated_Reschedule_Required__c, ' +
                'loan__Sent_To_ACH__c, ' +
                'loan__ACH_Filename__c, ' +
                'loan__Installment_Payment__c, '+
                'loan__Installment_Date__c, '+
                'loan__Loan_Snapshot__c, '+
                //ND-3311
                'loan__Is_Adjustment_Entry_Created__c, '+ //ND-3238
                'loan__Sent_To_ACH_On__c, '+
                'loan__Automated_Payment_Setup__c, ' +
                'loan__Automated_Payment_Setup__r.loan__Retry__c, ' +
                'loan__Automated_Payment_Setup__r.loan__Retry_Attempt_Interval__c, ' +
                'loan__Automated_Payment_Setup__r.loan__Return_Codes_for_Retry__c, ' +
                'loan__Automated_Payment_Setup__r.loan__Number_of_Retry_Attempts__c, ' +
                'loan__Automated_Payment_Setup__r.loan__Active__c, ' +
                'loan__Automated_Payment_Setup__r.loan__Payment_Mode__c, ' +
                'loan__Automated_Payment_Setup__r.loan__Apply_NSF_on_Attempt__c , ' +
                'loan__Automated_Payment_Setup__r.loan__Pending_Retry__c ';
                
    }
    
    global static String getOtherLoanTxnFields(){
        return 'Id, '+
               'Name, '+
               'loan__Actual_Interest_Only_Payments__c, '+
               'loan__Additional_Interest_Amt__c, '+
               'loan__Amortization_Term__c, ' +
               'loan__OT_Amount_to_Current__c, ' +
               'loan__Archived__c, ' +
               'loan__Backdated_Reschedule__c, ' +
               'loan__Bank_Account__c, ' +
               'loan__Bank_Origination_Fees__c, ' +
               'loan__Billing_Method__c, ' +
               'loan__Bill_Snapshot__c, ' +
               'loan__Charge__c, ' +
               'loan__Charged_Off_Capitalized_Fees__c, ' +
               'loan__Charged_Off_Capitalized_Interest__c, ' +
               'loan__Charged_Off_Date__c, '+
               'loan__Charged_Off_Fees__c, '+
               'loan__Charged_Off_Interest__c, ' +
               'loan__Charged_Off_Principal__c, '+
               'loan__Deposit_Snapshot__c, ' +
               'loan__Draw_Period_End_Date__c, ' +
               'loan__Draw_Term__c, '+
               'loan__Due_Date__c, '+
               'loan__Due_Ids__c, ' +
               'loan__Extend_Maturity_Date__c, ' +
               'loan__External_Id__c, ' +
               'loan__Fees_Capitalized__c, ' +
               'loan__Forecast_Streams__c, ' +
               'loan__Frequency_Cycle_of_Loan_Payment__c, ' +
               'loan__Frequency_of_Loan_Payment__c, ' +
               'loan__Funding_Stop_Basis__c, ' +
               'loan__Holiday_Schedule_Snapshot__c, ' +
               'loan__Interest_Amount_Accounted_For__c, ' +
               'loan__Interest_Capitalized__c, '+
               'loan__Interest_Component__c, '+
               'loan__Interest_Component_Snapshot__c, ' +
               'loan__Interest_Only_Payment_Amt__c, '+
               'loan__Interest_Only_Period__c, ' +
               'loan__Interest_Rate__c, ' +
               'loan__Interest_Rate_Change_Action__c, '+
               'loan__Interest_Rate_Change_Method__c, '+
               'loan__Internal_Accounting_Generated__c, ' +
               'loan__Investor_Rebate_Amount_On_Write_Off__c, ' +
               'loan__Ipt_Snapshot__c, '+
               'loan__Same_monthly_payment__c, '+
               'loan__Loan_Payment_Id__c, ' +
               'loan__Loan_Account__c, ' +
               'loan__Loan_Amount__c, ' +
               'loan__Loan_Disbursal_Transaction__c, ' +
               'loan__Loan_Payment_Transaction__c, ' +
               'loan__Loan_Snapshot__c, ' +
               'loan__Maintain_Delinquency__c, ' +
               'loan__Master_Archive_Object__c, ' +
               'loan__OT_Maturity_Date__c, ' +
               'loan__New_Buyback_Status__c, ' +
               'loan__New_Contingency_Status__c, '+
               'loan__New_Credit_Limit__c, '+
               'loan__New_Due_Day__c, ' +
               'loan__New_Index_Rate__c, '+
               'loan__New_Interest_Rate__c, ' +
               'loan__New_Second_Due_Day__c, ' +
               'loan__Next_Due_Date__c, '+
               'loan__Next_Due_Generation_Date__c, '+
               'loan__Number_of_Installments__c, ' +
               'loan__Number_Of_Interest_Only_Payments__c, '+
               'loan__Repayment_Extension_Days__c, ' +
               'loan__Old_Buyback_Status__c, ' +
               'loan__Old_Contingency_Status__c, '+
               'loan__Credit_Limit__c, '+
               'loan__Old_Due_Day__c, ' +
               'loan__Old_Index_Rate__c, ' +
               'loan__Old_Payment_Amount__c, ' +
               'loan__Old_Second_Due_Day__c, ' +
               'loan__Origination_Fees__c, ' +
               'loan__Parent_Transaction__c, ' +
               'loan__Passed_Term__c, ' +
               'loan__Payment_Amount__c, ' +
               'loan__Payment_Auto_Compute_Flag__c, ' +
               'loan__Payment_Tolerance_End_Date__c, ' +
               'loan__Payment_Tolerance_Fixed_Amount__c, '+
               'loan__Payment_Tolerance_Rate__c, '+
               'loan__Payment_Tolerance_Start_Date__c, ' +
               'loan__Pay_Off_Date__c, '+
               'loan__Periodic_Fee_Amount__c, ' +
               'loan__Primary_Repayment_Schedule_Summary_Ids__c, ' +
               'loan__Principal_Adjustment_Reschedule_Option__c, '+
               'loan__Principal_Remaining__c, '+
               'loan__Principal_Repayment_Start_Date__c, ' +
               'loan__Product_Code__c, ' +
               'loan__Promotion_Schedule_SnapShot__c, '+
               'loan__Protect_Claim__c, ' +
               'loan__Purchase_Price__c, ' +
               'loan__Rate_Schedule_Snapshot__c, '+
               'loan__Reference__c, '+
               'loan__Regenerate_Investor_AMZ_Schedule__c, ' +
               'loan__Rejected__c, ' +
               'loan__Repayment_Plan_Snapshot__c, ' +
               'loan__Repayment_Procedure__c, ' +
               'loan__Repayment_Start_Date__c, ' +
               'loan__Reschedule_Balance__c, ' +
               'loan__Reschedule_Option_On_Excess_Payment__c, ' +
               'loan__Reversed__c, ' +
               'loan__Reverse_Snapshot__c, ' +
               'loan__RSS_Snapshot__c, ' +
               'loan__Schedule_Snapshot__c, '+
               'loan__Second_Payment_Date__c, '+
               'loan__Step_Up_Snapshot__c, ' +
               'loan__Summary__c, '+
               'loan__Summary_Record_Id__c, ' +
               'loan__Pay_Off_Amount_As_Of_Today__c, ' +
               'loan__Total_Fees_Due__c, '+
               'loan__Total_Interest_Due__c, '+
               'loan__Txn_Amt__c, ' +
               'loan__Transaction_Creation_Date__c, ' +
               'loan__Txn_Date__c, ' +
               'loan__Description__c, ' +
               'loan__Transaction_Time__c, ' +
               'loan__Transaction_Type__c, ' +
               'loan__Unposted_Principal__c, ' +
               'loan__Waived_Additional_Interest__c, '+
               'loan__Waived_Interest__c ';        
    }
    
    global static String getLoanFieldsForOLT() {
        return 'loan__Loan_Account__r.name,'+
               'loan__Loan_Account__r.loan__Last_Transaction_Type__c,'+
               'loan__Loan_Account__r.Id,'+
               'loan__Loan_Account__r.loan__Last_Accrual_Date__c,'+
               'loan__Loan_Account__r.loan__Master_Loan_Last_Transaction_Id__c,'+
               'loan__Loan_Account__r.loan__Principal_Remaining__c, '+
               'loan__Loan_Account__r.loan__capitalized_fee__c, '+
               'loan__Loan_Account__r.loan__capitalized_Interest__c, '+
               'loan__Loan_Account__r.loan__Last_Transaction_Timestamp__c, '+
               'loan__Loan_Account__r.loan__Last_Transaction_Type__c, '+
               'loan__Loan_Account__r.loan__Last_Transaction_Id__c, '+
               'loan__Loan_Account__r.loan__disbursed_Amount__c, '+
               'loan__Loan_Account__r.loan__Total_Refinance_Amount_Actual__c, '+
               'loan__Loan_Account__r.loan__Total_Pre_Paid_Fees__c, '+
               'loan__Loan_Account__r.loan__Product_Type__c, '+
               'loan__Loan_Account__r.loan__Loan_Status__c, '+
               'loan__Loan_Account__r.loan__Interest_Rate__c, '+
               'loan__Loan_Account__r.loan__Interest_Posted__c, '+
               'loan__Loan_Account__r.loan__Frequency_of_Loan_Payment__c, '+
               'loan__Loan_Account__r.loan__Time_Counting_Method__c, '+
               'loan__Loan_Account__r.loan__Next_Installment_Date__c, '+
               'loan__Loan_Account__r.loan__Flexible_Rate__c, '+
               'loan__Loan_Account__r.loan__Interest_Calculation_Method__c, '+
               'loan__Loan_Account__r.loan__Capitalization_Frequency__c, '+
               'loan__Loan_Account__r.loan__Credit_Limit_Current__c, '+
               'loan__Loan_Account__r.loan__Loan_Balance__c, '+
               'loan__Loan_Account__r.loan__Loan_Amount__c, '+
               'loan__Loan_Account__r.loan__Revolving__c, '+
               'loan__Loan_Account__r.loan__Interest_type__c, '+
               'loan__Loan_Account__r.loan__Payoff_Fee_Indicator__c, '+
               'loan__Loan_Account__r.loan__Scheduled_Fee_Amount_In_PayOff__c, '+
               'loan__Loan_Account__r.loan__Total_Amount_Disbursed__c, '+
               'loan__Loan_Account__r.loan__Accrual_Stop_Indicator__c, '+
               'loan__Loan_Account__r.loan__Payment_Application_Mode__c, '+
               'loan__Loan_Account__r.loan__Loan_Parameters__c, '+
               'loan__Loan_Account__r.loan__Loan_Parameters__r.id, '+
               'loan__Loan_Account__r.loan__Loan_Parameters__r.name, '+
               'loan__Loan_Account__r.loan__Loan_Parameters__r.loan__Advance_Interest__c, '+
               'loan__Loan_Account__r.loan__Loan_Parameters__r.loan__Minimum_Interest_Option__c, '+
               'loan__Loan_Account__r.loan__Loan_Parameters__r.loan__Auto_Change_Deposit_Rate__c, '+
               'loan__Loan_Account__r.loan__Loan_Product_Name__r.id, '+
               'loan__Loan_Account__r.loan__Loan_Product_Name__r.name, '+
               'loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__General_Rounding_Mode__c , '+
               'loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__Digits_After_Decimals__c, '+
               'loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__enable_adjustment_entry__c, '+
               'loan__Loan_Account__r.loan__Loan_Product_Name__r.loan__Create_Summaries__c, '+
               'loan__Loan_Account__r.loan__is_Interest_Posting_Enabled__c';
    }
    
}