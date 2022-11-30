@isTest
public class CPQ_Flow_GenerateRenewalQuoteTest {

    @TestSetup
    static void createTestData(){
        Account a = CPQ_TestFactory.createAccount();
        Opportunity o = CPQ_TestFactory.createOpportunity(a.Id);
        // Setup Contracts
        List<Contract> insertContracts = new List<Contract>();
        for (Integer i = 0; i < 2; i++) {
            Contract newContract = CPQ_TestFactory.createContract(a.Id, false);
            newContract.SBQQ__RenewalOpportunity__c = o.Id;
            newContract.StartDate = Date.today().addMonths(i);
            insertContracts.add(newContract);
        }
        insert insertContracts;
    }

    @isTest static void generateCombinedRenewalQuoteTest(){
        // Variables
        CPQ_Flow_GenerateRenewalQuote.Request req = new CPQ_Flow_GenerateRenewalQuote.Request();
        req.renewalContracts = [SELECT Id, StartDate, EndDate, SBQQ__RenewalOpportunity__c, ContractNumber FROM Contract];
        req.masterContractId = req.renewalContracts[0].Id;
        // Start Test
        test.startTest();
        CPQ_Flow_GenerateRenewalQuote.generateRenewalQuote(new List<CPQ_Flow_GenerateRenewalQuote.Request>{req});
        test.stopTest();
        // Validate Results
        Integer quoteCheck = [SELECT COUNT() FROM SBQQ__Quote__c];
        Assert.areEqual(1, quoteCheck, 'Expected 1 Quote');
    }

    @isTest static void setMasterContractTest(){
        // Test Variables
        Map<Id, CPQ_Flow_GenerateRenewalQuote.MasterContract> masterContractMap = new Map<Id, CPQ_Flow_GenerateRenewalQuote.MasterContract>();
        Id key = [SELECT Id FROM Contract LIMIT 1].Id;
        Date endDate = Date.today();
        Date earlierEndDate = endDate.addMonths(-1);
        Date laterEndDate = endDate.addMonths(1);
        test.startTest();
        // First Date
        CPQ_Flow_GenerateRenewalQuote.setMasterContract(key,endDate,masterContractMap);
        // Earlier Date
        CPQ_Flow_GenerateRenewalQuote.setMasterContract(key,earlierEndDate,masterContractMap);
        // Later Date
        CPQ_Flow_GenerateRenewalQuote.setMasterContract(key,laterEndDate,masterContractMap);
        test.stopTest();
        CPQ_Flow_GenerateRenewalQuote.MasterContract mc = masterContractMap.get(key); 
        Assert.areEqual(3, mc.contractCount,'Should have 3 contract records in the map');
        Assert.areEqual(earlierEndDate, mc.EarliestStartDate, 'Earliest Start Date');
        Assert.areEqual(laterEndDate, mc.LatestStartDate, 'Latest Start Date');
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
        CPQ_Flow_GenerateRenewalQuote.checkPrimaryQuotes(quoteId, opportunityId, quoteUpdateMap);
        test.stopTest();
        Assert.areEqual(1, quoteUpdateMap.size(),'Should have 1 record in the map');
    }

    @isTest static void setTermTest(){
        // Test Variables
        Date startDate = Date.today();
        Date oneYear = startDate.addYears(1);
        Date twoYear = startDate.addYears(2);
        test.startTest();
        Integer twelveMonthTerm = CPQ_Flow_GenerateRenewalQuote.setTerm(startDate,oneYear);
        Integer twentyFourMonthTerm = CPQ_Flow_GenerateRenewalQuote.setTerm(startDate,twoYear);
        test.stopTest();
        Assert.areEqual(12, twelveMonthTerm, 'Should be a 12 month term');
        Assert.areEqual(24, twentyFourMonthTerm, 'Should be a 24 month term');
    }

    @isTest static void checkErrorsTest(){
        // Test Variables
        String validateError;
        CPQ_Flow_GenerateRenewalQuote.Results newResult = new CPQ_Flow_GenerateRenewalQuote.Results();
        List<CPQ_Flow_GenerateRenewalQuote.Results> resultList = new List<CPQ_Flow_GenerateRenewalQuote.Results>{newResult};
        CPQ_UtilityClass.errorMessages = new List<String>{'Test Error'};
        // Start Test
        test.startTest();
        CPQ_Flow_GenerateRenewalQuote.checkErrors(resultList);
        test.stopTest();
        // Check and Validate
        for(CPQ_Flow_GenerateRenewalQuote.Results res : resultList){
            validateError = res.errorMessageString;
        }
        Assert.areEqual('Test Error', validateError, 'Messages should match');
    }
}