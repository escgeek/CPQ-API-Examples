@isTest
public class CPQ_Flow_GenerateAmendmentQuoteTest {

    @TestSetup
    static void createTestData(){
        Account a = CPQ_TestFactory.createAccount();
        Opportunity o = CPQ_TestFactory.createOpportunity(a.Id);
        Contract newContract = CPQ_TestFactory.createContract(a.Id);
    }

    @isTest static void generateAmendmentQuoteTest(){
        // Variables
        CPQ_Flow_GenerateAmendmentQuote.Request req = new CPQ_Flow_GenerateAmendmentQuote.Request();
        req.opportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        req.contractId = [SELECT Id FROM Contract LIMIT 1].Id;
        // Start Test
        test.startTest();
        CPQ_Flow_GenerateAmendmentQuote.generateAmendmentQuote(new List<CPQ_Flow_GenerateAmendmentQuote.Request>{req});
        test.stopTest();
        // Validate Results
        Integer quoteCheck = [SELECT COUNT() FROM SBQQ__Quote__c];
        Assert.areEqual(1, quoteCheck, 'Expected 1 Quote');
    }

    @isTest static void checkPrimaryQuotesTest(){
        // Test Variables
        Opportunity o = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Map<Id, SBQQ__Quote__c> quoteUpdateMap = new Map<Id, SBQQ__Quote__c>();
        Id quoteId = 'a0qDn000000ZPWwIAO'; // Fake quote id
        Id opportunityId = o.Id;
        Id accountId = o.AccountId;
        SBQQ__Quote__c q = CPQ_TestFactory.createQuote(accountId, opportunityId);
        test.startTest();
        CPQ_Flow_GenerateAmendmentQuote.checkPrimaryQuotes(quoteId, opportunityId, quoteUpdateMap);
        test.stopTest();
        Assert.areEqual(1, quoteUpdateMap.size(),'Should have 1 record in the map');
    }

    @isTest static void checkErrorsTest(){
        // Test Variables
        String validateError;
        CPQ_Flow_GenerateAmendmentQuote.Results newResult = new CPQ_Flow_GenerateAmendmentQuote.Results();
        List<CPQ_Flow_GenerateAmendmentQuote.Results> resultList = new List<CPQ_Flow_GenerateAmendmentQuote.Results>{newResult};
        CPQ_UtilityClass.errorMessages = new List<String>{'Test Error'};
        // Start Test
        test.startTest();
        CPQ_Flow_GenerateAmendmentQuote.checkErrors(resultList);
        test.stopTest();
        // Check and Validate
        for(CPQ_Flow_GenerateAmendmentQuote.Results res : resultList){
            validateError = res.errorMessageString;
        }
        Assert.areEqual('Test Error', validateError, 'Messages should match');
    }
}