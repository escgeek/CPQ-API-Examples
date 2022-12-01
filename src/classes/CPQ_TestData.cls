/*  
Use developer console to fire these commands:
CPQ_TestData.create(); // Creates a new Account, Contact, Opp, Quote, Quote Line, and Quote Group
CPQ_TestData.createQuote('AccountID','OpportunityId','Primary Quote','With Quote Lines','With Groups')
*/
public class CPQ_TestData {

public String salt;
    public Id priceBookId;

    public CPQ_TestData(){
        Datetime uniqueDate = dateTime.now();
        salt = uniqueDate.format('HHmmss');
        priceBookId = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id, Name FROM Pricebook2 WHERE IsStandard = true AND IsActive = true LIMIT 1].Id;
    }

    public static void create(){ // Craete Account
        Account a = createAccount();
        create(a);
    }
    public static void create(Id accountId){ // Use Existing Account
        Account a = [SELECT Id FROM Account WHERE Id = :accountId];
        create(a);
    }
    public static void create(Account a){ // Create the rest of the data
        Contact c = createContact(a.Id);
        Opportunity o = createOpportunity(a.Id, c.Id);
        // Quote Flags: Account Id - Opportunity Id - Primary Quote - With Line Items - With Groups
        SBQQ__Quote__c q = createQuote(a.Id, o.Id, true, true, true);
    }

    public static Contact createContact(Id accountId){
        CPQ_TestData testData = new CPQ_TestData();
        Contact c = new Contact(
            FirstName = 'Jake',
            LastName = testData.salt + 'Elwood',
            Email = 'Jake.Elwood' + testData.salt + '@gmail.com',
            AccountId = accountId,
            MailingStreet = testData.salt + ' ßW Addison St',
            MailingCity = 'Chicago',
            MailingState = 'Illinois',
            MailingPostalCode = '60613',
            MailingCountry = 'United States',
            LeadSource = 'Web'
        );
        insert c;
        return c;
    }

    public static Account createAccount(){
        CPQ_TestData testData = new CPQ_TestData();
        //Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId(); // Example of how to get the record type id by name
        Account a = new Account(
            Name = testData.salt + ' - CPQ Test Account', 
            Type = 'Prospect',
            //RecordTypeId = recordTypeId,
            BillingStreet = testData.salt + ' Market Street', 
            BillingCity = 'San Francisco', 
            BillingState = 'California', 
            BillingPostalCode = '94105', 
            BillingCountry = 'United States', 
            ShippingStreet = testData.salt + ' Market Street', 
            ShippingCity = 'San Francisco', 
            ShippingState = 'California', 
            ShippingPostalCode = '94105', 
            ShippingCountry = 'United States'
            /* Phone and Web will trip the duplicate account rules on by default 
            Phone = '919-555-1212', 
            Fax = '919-555-1212', 
            Website = 'http://test33.com' */
        );
        insert a;
        return a;
    }

    public static Opportunity createOpportunity(Id accountId, Id contactId){
        CPQ_TestData testData = new CPQ_TestData();
        Date closeDate = Date.today().addMonths(1).toStartOfMonth().addDays(-1);
        Opportunity o = new Opportunity(
                Name = 'CS Test Opportunity - ' +  datetime.now().format(),
                AccountId = accountId,
                ContactId = contactId,
                CloseDate = closeDate,
                Pricebook2Id = testData.priceBookId,
                SBQQ__QuotePricebookId__c = testData.priceBookId,
            	StageName = 'Prospecting' // Update this to your org's first opportunity stage
                //Test_Record__c = true // I like to use something like this for easy cleanup and report filtering if used in production
            );
        insert o;
        return o;
    }
    
    public static SBQQ__Quote__c createQuote(Id accountId, Id opportunityId){
        return createQuote(accountId,opportunityId,true,true,true);
    }
    
    public static SBQQ__Quote__c createQuote(Id accountId, Id opportunityId, boolean primaryFlag, boolean withLines, boolean withGroups){
        CPQ_TestData testData = new CPQ_TestData();
        SBQQ__Quote__c q = new SBQQ__Quote__c (
            SBQQ__Account__c = accountId,
            SBQQ__Opportunity2__c = opportunityId,
            SBQQ__Type__c = 'Quote',
            SBQQ__Primary__c = primaryFlag,
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__PaymentTerms__c = 'Net 30',
            SBQQ__BillingFrequency__c = 'Monthly',
            SBQQ__StartDate__c = Date.today(),
            SBQQ__PricebookId__c = testData.priceBookId,
            SBQQ__PriceBook__c = testData.priceBookId,
            SBQQ__LineItemsGrouped__c = withGroups
        );
        insert q;
        SBQQ__QuoteLineGroup__c qlg = (withGroups) ? createQuoteLineGroup(q.Id, opportunityId) : new SBQQ__QuoteLineGroup__c();
        createQuoteLines(q.Id, opportunityId, qlg, withLines);
        return q;
    }

    public static void createQuoteLines(Id quoteId, Id opportunityId, SBQQ__QuoteLineGroup__c qlg, boolean withLines){
        if(withLines){
            CPQ_TestData testData = new CPQ_TestData();
            // Variables
            List<CPQ_API_Helper.ProductModel> productModels = new List<CPQ_API_Helper.ProductModel>();
            // Add Products
            Product2 p = lookupProduct('SOFTPHONE'); // Product found in Trailhead Org's
            CPQ_API_Helper.QuoteModel quoteModel = CPQ_API_Helper.read(quoteId);
            CPQ_API_Helper.ProductModel productModel = CPQ_API_Helper.read(p.Id, testData.priceBookId, 'USD'); //Use Read Product API to obtain a ProductModel
            productModels.add(productModel);
            // Repeat to add additional products
            CPQ_API_Helper.QuoteModel quoteWithProducts = CPQ_API_Helper.add(quoteModel, productModels, 0);
            for(CPQ_API_Helper.QuoteLineModel ql : quoteWithProducts.lineItems){
                ql.record.SBQQ__Quantity__c = 12;
                ql.record.SBQQ__ListPrice__c = 25;
                ql.record.SBQQ__Group__c = qlg.Id; // Associate the Product to a group
            }
            CPQ_API_Helper.calculate(quoteWithProducts, 'CPQ_API_QuoteCallBack'); 
            
        }
    }

    public static Product2 lookupProduct(String productCode){
        Product2 p;
        try { // New Orgs this will fail until the product(s) are updated
            p = [SELECT Id FROM Product2 WHERE ProductCode = :productCode LIMIT 1]; 
        } catch (System.QueryException e) {
            System.debug('Product Not Found! - ' + e.getMessage());
        }
        return p;
    }

    public static SBQQ__QuoteLineGroup__c createQuoteLineGroup(Id quoteId, Id opportunityId){
        SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c(
            Name = 'Group1',
            SBQQ__Quote__c = quoteId,    
            SBQQ__Number__c = 1,
            SBQQ__CustomerTotal__c = 0,
            SBQQ__ListTotal__c = 0,
            SBQQ__NetTotal__c = 0
        );
        insert qlg;
        return qlg;
    }
}