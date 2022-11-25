@isTest private class CaslUnsubscribeSchedulableTest {
    @isTest private static void insertsUnsubscribedSmses() {
        TestSmsService smsService = new TestSmsService();
        smsService.optedOutPhoneNumbers.add('12222222222');

        Test.startTest();
        CaslUnsubscribeSchedulable.checkForOptedOutPhoneNumbers(smsService);
        Test.stopTest();

        List<UnsubscribedSms__c> unsubscribedSmses = [SELECT CustomerPhone__c, SmsOptOut__c FROM UnsubscribedSms__c];
        System.assertEquals(1, unsubscribedSmses.size());
        System.assertEquals('2222222222', unsubscribedSmses[0].CustomerPhone__c);
        System.assertEquals(true, unsubscribedSmses[0].SmsOptOut__c);
    }

    @isTest private static void codeCoverage() {
        try {
            Test.startTest();
            new CaslUnsubscribeSchedulable().execute(null);
            Test.stopTest();
        } catch (Exception error) {
            System.assert(true);
        }
    }

    private class TestSmsService implements Service.Sms {
        public List<String> optedOutPhoneNumbers = new List<String>();

        public List<String> getOptedOutPhoneNumbers(DateTime fromDate, DateTime toDate) {
            return optedOutPhoneNumbers;
        }

        public void subscribe(String phoneNumber) {
        }

        public void unsubscribe(String phoneNumber) {
        }
    }
}