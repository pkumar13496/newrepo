public class validateEmployeeLoan{

    public validateEmployeeLoan(ApexPages.StandardController controller) {

    }

    public validateEmployeeLoan() {
    }

public String currentRecordId {get;set;}

public String parameterValue {get;set;}

public Account acc{get;set;}

 

    public PageReference EmployeeLoanValidationmethod() {

        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
        system.debug('currentRecordId is '+currentRecordId);

        list<loan__Loan_Account__c> lstacc = [select  loan__Account__r.Customer_Contact__r.Employee_Code__c from loan__Loan_Account__c where id =: currentRecordId ];
        
        list<profile> profile=[Select Name from Profile where Id =:userinfo.getProfileId()];
        system.debug('profile[0].name is '+profile[0].name);
        system.debug('lstacc[0].loan__Account__r.Customer_Contact__r.Employee_Code__c '+lstacc[0].loan__Account__r.Customer_Contact__r.Employee_Code__c);
        
        if(lstacc[0].loan__Account__r.Customer_Contact__r.Employee_Code__c!=null && (profile[0].Name=='Branch Manager Standard Platform User FUSION' || profile[0].Name=='Branch Standard Platform User FUSION') ){
            
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'You do not have access to view this loan.'));
            return null;
        }
        else{
       
        String redirecturl ='/apex/loan__tabbedLoanAccount?id='+currentRecordId+'&sfdc.override=1';

    PageReference newpage = new PageReference(redirecturl);
    newpage.setRedirect(true);
    return newpage;
        }

    }

}