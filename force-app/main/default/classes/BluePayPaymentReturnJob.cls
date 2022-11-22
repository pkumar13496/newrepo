global class BluePayPaymentReturnJob extends clcommon.DynamicJob {

    private String query;
    private Map<Id,String> returnCodeMap;
    private final static String JOB_NAME = 'BluePayPaymentReturnJob';
    
    global BluePayPaymentReturnJob() {
    	super(JOB_NAME,null);
    }
    
    global BluePayPaymentReturnJob(String query, Map<Id,String> returnCodeMap) {
        super(JOB_NAME, query);
        this.returnCodeMap = returnCodeMap;
    }
    
    global override void doInitialize() {} // do nothing
    
    global override String getRuntimeQuery() {
    	//Add run time query when query passed in the constructor is null.
        String query = getLoanPaymentReturnQuery(null); 
    	return query;
    }
    
    global override String getRuntimeQueryForPipelinedExecution(Set<Id> records) {
        return null;
    }
    
    global override void doStart(Database.BatchableContext bc) {}
    
    global override void doExecute(Database.BatchableContext bc, List<sObject> scope) {
        System.debug('Entered JOB');
        BluePayPaymentReturnHandler returnACHHandler = new BluePayPaymentReturnHandler(scope, returnCodeMap);
        returnACHHandler.processReturns();
    }
    
    global override void doFinish(Database.BatchableContext bc){} // do nothing
    
    global static String getLoanPaymentReturnQuery(Set<ID> ids){
        mfiflexUtil.ExecutionContext ec = mfiflexUtil.ExecutionContext.getExecContext();
        mfiflexUtil.ObjectCache invLoanPmtROC = ec.getObject('ReturnedLoanPayments');
        if(invLoanPmtROC != null) {
            ec.deleteObject('ReturnedLoanPayments'); 
        }
        invLoanPmtROC = ec.createObject('ReturnedLoanPayments' ,
                                                             'loan__Loan_Payment_Transaction__c');
        invLoanPmtROC.addFields(BatchUtils.getLoanPaymentTxnFields());
        invLoanPmtROC.addFields(BatchUtils.getLoanFieldsForLPT());
        invLoanPmtROC.addFields( 'Charge_NSF__c,Rejected_Transaction__c,Payment_Mode_Name__c,Return_Description__c');
        String whereClause = '';
        system.debug(LoggingLevel.ERROR, 'Ids :: ' + ids);
        if(ids != null) {
            whereClause += 'ID IN :ids AND ';  
            invLoanPmtROC.addNamedParameter('ids', ids);
        }
        whereClause += '(Payment_Mode_Name__c =:paymentMode AND loan__reversed__c = false)';
        invLoanPmtROC.addNamedParameter('paymentMode', 'Pre-Authorized Visa Debit');
        invLoanPmtROC.setWhereClause(whereClause);
        invLoanPmtROC.buildQuery();
        System.debug(invLoanPmtROC.getQuery());
        return invLoanPmtROC.getQuery();
    }
    
}