public class ValidateEmployeeAccount {
    
     public ValidateEmployeeAccount(ApexPages.StandardController controller) {

    }

    public ValidateEmployeeAccount() {
    }

public String currentRecordId {get;set;}

public String parameterValue {get;set;}
public Boolean isEmployee {get;set;}

public Account acc{get;set;}

 

    public void EmployeeAccountValidationmethod() {

        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
        system.debug('currentRecordId is '+currentRecordId);

        list<Account> lstacc = [select Customer_Contact__r.Employee_Code__c from Account where id =: currentRecordId ];
        
        list<profile> profile=[Select Name from Profile where Id =:userinfo.getProfileId()];
        system.debug('profile[0].name is '+profile[0].name);
        system.debug('lstacc[0].Customer_Contact__r.Employee_Code__c '+lstacc[0].Customer_Contact__r.Employee_Code__c);
        
        if(lstacc[0].Customer_Contact__r.Employee_Code__c!=null && (profile[0].Name=='Branch Manager Standard Platform User FUSION' || profile[0].Name=='Branch Standard Platform User FUSION') ){
            isEmployee=false;
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'You do not have access to view this Account.'));
           // return null;
        }
        else{
        isEmployee=true;
        /*
       system.debug('im in else');
        String redirecturl ='/lightning/r/'+currentRecordId+'/view';
        //String redirecturl ='/'+currentRecordId;

    PageReference newpage = new PageReference(redirecturl);
    newpage.setRedirect(true);
            system.debug('redirecturl '+redirecturl);
    return newpage;*/
        }

    }
    public void EmployeeContactValidationmethod() {
            currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
        system.debug('currentRecordId is '+currentRecordId);

        list<Contact> lstacc = [select Employee_Code__c from Contact where id =: currentRecordId ];
        
        list<profile> profile=[Select Name from Profile where Id =:userinfo.getProfileId()];
        system.debug('profile[0].name is '+profile[0].name);
        //system.debug('lstacc[0].Customer_Contact__r.Employee_Code__c '+lstacc[0].Customer_Contact__r.Employee_Code__c);
        
        if(lstacc[0].Employee_Code__c!=null && (profile[0].Name=='Branch Manager Standard Platform User FUSION' || profile[0].Name=='Branch Standard Platform User FUSION') ){
            isEmployee=false;
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'You do not have access to view this Contact.'));
           // return null;
        }
        else{
        isEmployee=true;
        /*
       system.debug('im in else');
        String redirecturl ='/lightning/r/'+currentRecordId+'/view';
        //String redirecturl ='/'+currentRecordId;

    PageReference newpage = new PageReference(redirecturl);
    newpage.setRedirect(true);
            system.debug('redirecturl '+redirecturl);
    return newpage;*/
        }   
    }

}