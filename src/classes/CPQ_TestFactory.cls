@isTest
public class CPQ_TestFactory {

    public static String salt(){
        Datetime uniqueDate = dateTime.now();
        return uniqueDate.format('HHmmss');
    }

    public static Account createAccount(){
        return createAccount(true);
    }
    public static Account createAccount(Boolean insertFlag){
        //Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Account').getRecordTypeId();
        Account a = new Account(
            Name = 'CPQ Test Account ' + salt(), 
            Type = 'Prospect',
            BillingStreet = 'Market Street', 
            BillingCity = 'San Francisco', 
            BillingState = 'California', 
            BillingPostalCode = '302022', 
            BillingCountry = 'United States', 
            Phone = '919-555-1212', 
            Fax = '919-555-1212', 
            Website = 'http://salesforce.com'
        );
        if(insertFlag){
            insert a;
        }
        return a;
    }

    public static Contact createContact(Id accountId){
        return createContact(accountId,true);
    }
    public static Contact createContact(Id accountId, Boolean insertFlag){
        Contact c = new Contact(
            FirstName = 'Jake',
            LastName = salt() + 'Elwood',
            Email = 'Jake.Elwood' + salt() + '@gmail.com',
            AccountId = accountId,
            MailingStreet = '1060 W Addison St',
            MailingCity = 'Chicago',
            MailingState = 'Illinois',
            MailingPostalCode = '60613',
            MailingCountry = 'United States',
            LeadSource = 'Web'
        );
        if(insertFlag){
            insert c;
        }
        return c;
    }

    public static Opportunity createOpportunity(Id accountId){
        return createOpportunity(accountId,true);
    }
    public static Opportunity createOpportunity(Id accountId, boolean insertFlag){
        Date closeDate = Date.today().addMonths(1).toStartOfMonth().addDays(-1); // End of the Month
        Opportunity newOpp = new Opportunity(
            Name = 'CPQ Test Opportunity - ' +  datetime.now().format(),
            AccountId = accountId,
            CloseDate = closeDate,
            //Pricebook2Id = testData.priceBookId.Id,
            //SBQQ__QuotePricebookId__c = testData.priceBookId.Id,
            StageName = 'Prospecting'
        );
        if(insertFlag){ insert newOpp; }
        return newOpp;
    }

    public static SBQQ__Quote__c createQuote(Id accountId, Id opportunityId){
        return createQuote(accountId,opportunityId,true);
    }
    public static SBQQ__Quote__c createQuote(Id accountId, Id opportunityId, boolean insertFlag){
        SBQQ__Quote__c q = new SBQQ__Quote__c (
            SBQQ__Account__c = accountId,
            SBQQ__Opportunity2__c = opportunityId,
            SBQQ__Type__c = 'Quote',
            SBQQ__Primary__c = true,
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__PaymentTerms__c = 'Net 30',
            SBQQ__BillingFrequency__c = 'Monthly',
            SBQQ__StartDate__c = Date.today()
            //SBQQ__PricebookId__c = testData.priceBookId.Id,
            //SBQQ__PriceBook__c = testData.priceBookId.Id,
            //SBQQ__LineItemsGrouped__c = true
        );
        if(insertFlag){
            insert q;
        }
        return q;
    }

    public static Contract createContract(Id accountId){
        return createContract(accountId,true);
    }
    public static Contract createContract(Id accountId, boolean insertFlag){
        Contract c = new Contract (
            AccountId = accountId,
            StartDate = Date.today(),
            ContractTerm = 12
        );

        if(insertFlag) insert c;
        return c;
    }

    public static Pricebook2 createPriceBook(String pbName, boolean insertFlag){
        Pricebook2 pbook = new pricebook2(
            Name = pbName,
            IsActive = TRUE
        );
        if(insertFlag){ insert pbook; }
        return pbook;
    }

    public static PricebookEntry createPricebookEntry(Id pId, Id pbId, Double salesPrice){
        Id spbId = Test.getStandardPricebookId();
        salesPrice = (salesPrice == NULL) ? 0 : salesPrice;
        // Standard Price Book
        PricebookEntry pbEntry = new PricebookEntry(
            pricebook2id = spbId, 
            product2id = pId, 
            unitprice = salesPrice, 
            isActive = true
        );
        insert pbEntry;
        // Specific Test Price Book
        pbEntry = new PricebookEntry(
            pricebook2id = pbId, 
            product2id = pId, 
            unitprice = salesPrice, 
            isActive = true
        );
        insert pbEntry;
        return pbEntry;
    }

    public static Product2 createBasicRenewableProduct(){
        return createBasicRenewableProduct(true);
    }
    public static Product2 createBasicRenewableProduct(boolean insertFlag){
        Product2 p = new Product2(
            isActive = true,
            Name = 'Softphone License',
            ProductCode = 'SOFTPHONE',
            SBQQ__BillingFrequency__c = 'Monthly',
            SBQQ__BillingType__c = 'Advance',
            SBQQ__ChargeType__c = 'Recurring',
            SBQQ__DefaultQuantity__c = 1.0,
            SBQQ__PriceEditable__c = true,
            SBQQ__PricingMethod__c = 'List',
            SBQQ__QuantityEditable__c = true,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__SubscriptionType__c = 'Renewable'
        );
        if(insertFlag){ insert p; }
        return p;
    }
}