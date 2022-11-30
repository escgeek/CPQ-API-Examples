@isTest
public class CPQ_TestDataTest {

    @TestSetup
    static void createData(){
        CPQ_TestFactory.createBasicRenewableProduct();
    }

    @isTest static void createDataTest(){
        test.startTest();
        CPQ_TestData.create();
        Account a = [SELECT Id FROM Account LIMIT 1];
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        CPQ_TestData.createQuote(a.Id, o.Id);
        test.stopTest();
        Integer quoteCount = [SELECT count() FROM SBQQ__Quote__c];
        Assert.areEqual(2, quoteCount, 'Should be 2 Quotes');
    }

    @isTest static void createAccountTest(){
        test.startTest();
        Account a = CPQ_TestFactory.createAccount();
        CPQ_TestData.create(a.Id);
        test.stopTest();
        Integer accountCount = [SELECT count() FROM Account];
        Assert.areEqual(1, accountCount, 'Should be 1 Accounts');
    }

    @isTest static void nullsTest(){
        test.startTest();
        CPQ_TestData.lookupProduct('123');
        test.stopTest();
    }

}