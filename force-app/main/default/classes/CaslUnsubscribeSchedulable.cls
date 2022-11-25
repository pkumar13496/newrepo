public without sharing class CaslUnsubscribeSchedulable implements Schedulable {
    public void execute(SchedulableContext SC) {
        checkForOptedOutPhoneNumbers();
    }

    @future(callout=true) private static void checkForOptedOutPhoneNumbers() {
        checkForOptedOutPhoneNumbers(new ServiceMulesoftSms());
    }

    @testVisible private static void checkForOptedOutPhoneNumbers(Service.Sms smsService) {
        DateTime startDateTime = DateTime.newInstance(System.today().addDays(-1), Time.newInstance(0, 0, 0, 0));
        DateTime endDateTime = DateTime.newInstance(System.today().addDays(0), Time.newInstance(23, 59, 59, 999));

        List<String> optedOutPhoneNumbers = smsService.getOptedOutPhoneNumbers(startDateTime, endDateTime);
        Map<String, UnsubscribedSms__c> unsubscribeSmses = new Map<String, UnsubscribedSms__c>();
        for (String optedOutPhoneNumber : optedOutPhoneNumbers) {
            unsubscribeSmses.put(optedOutPhoneNumber, new UnsubscribedSms__c(CustomerPhone__c = optedOutPhoneNumber.removeStart('1'), SmsOptOut__c = true));
        }
        UnsubscribedSmsTrigger.disableSmsService = true;
        upsert unsubscribeSmses.values() CustomerPhone__c;
    }
}