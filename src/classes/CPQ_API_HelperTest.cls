@isTest
public class CPQ_API_HelperTest {

    // Method Tests

    @TestSetup
    static void setup() {
        // Variables
        Account a = CPQ_TestFactory.createAccount();
        Contact c = CPQ_TestFactory.createContact(a.Id);
        Opportunity o = CPQ_TestFactory.createOpportunity(a.Id);

        // Create a Fixed Price subscription and a PoT product
        Product2 p1 = new Product2(
            Name = 'FixedPriceProduct', 
            IsActive = true, 
            SBQQ__SubscriptionPricing__c = 'Fixed Price', 
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__SubscriptionType__c = 'Renewable'
        );
        Product2 p2 = new Product2(
            Name = 'PotProduct', 
            IsActive = true, 
            SBQQ__SubscriptionPricing__c = 'Percent Of Total', 
            SBQQ__SubscriptionTerm__c = 12, 
            SBQQ__SubscriptionType__c = 'Renewable'
        );
        insert new List<Product2>{p1,p2};

        Pricebook2 pb = CPQ_TestFactory.createPriceBook('Sales', true);
        Decimal salesPrice = 1000.00;
        PricebookEntry pbe = CPQ_TestFactory.createPricebookEntry(p1.Id, pb.Id, 100);
        // Create a Contract
        Contract contract = new Contract(
            AccountId = a.Id, 
            SBQQ__PreserveBundleStructureUponRenewals__c = true, 
            StartDate = Date.today(),
            ContractTerm = 12
        );
        insert contract;
        // Add Percent Of Total Subscription to Contract
        Date endDate = Date.today().addYears(5);
        SBQQ__Subscription__c subscriptionPOT = new SBQQ__Subscription__c(
            SBQQ__Contract__c = contract.Id, 
            SBQQ__Product__c = p2.Id, 
            SBQQ__Quantity__c = 1, 
            SBQQ__SubscriptionEndDate__c = endDate
        );
        insert subscriptionPOT;
        // Add Fixed Price Subscription to Contract
        SBQQ__Subscription__c subscriptionFP = new SBQQ__Subscription__c(
            SBQQ__Contract__c = contract.Id, 
            SBQQ__Product__c = p1.Id, 
            SBQQ__Quantity__c = 1, 
            SBQQ__RequiredById__c = subscriptionPOT.Id, 
            SBQQ__SubscriptionEndDate__c = endDate);
        insert subscriptionFP;
        
    }

	@IsTest static void getQuoteModelTest(){
        Account a = [SELECT Id FROM Account LIMIT 1];
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c quote = CPQ_TestFactory.createQuote(a.Id, o.Id);
		CPQ_API_Helper.QuoteModel quoteModel = CPQ_API_Helper.read(quote.Id);
	}

	@IsTest static void loadProductTest(){
		Product2 p2 =  [SELECT Id FROM Product2 LIMIT 1];
		CPQ_API_Helper.ProductModel productModel = CPQ_API_Helper.read(p2.Id, Test.getStandardPricebookId(), 'USD');
	}

    @IsTest static void amendContractTest(){
        // Test Variables
        Id contractId = [SELECT Id FROM Contract LIMIT 1].Id;
        // Start Test
        Test.startTest();
        CPQ_API_Helper.amendContract(contractId);
		Test.stopTest();
	    // Validate Results
        Integer quoteCheck = [SELECT COUNT() FROM SBQQ__Quote__c];
        Assert.areEqual(1, quoteCheck, 'Expected 1 Quote');
	}

    @isTest static void renewContractTest(){
        // Test Variables
        Id contractId = [SELECT Id FROM Contract LIMIT 1].Id;
        // Start Test
        Test.startTest();
        CPQ_API_Helper.renewContract(contractId);
		Test.stopTest();
	    // Validate Results
        Integer quoteCheck = [SELECT COUNT() FROM SBQQ__Quote__c];
        Assert.areEqual(1, quoteCheck, 'Expected 1 Quote');
    }

    @isTest 
    static void methodsTest(){

        // Quote
        Account a = [SELECT Id FROM Account LIMIT 1];
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        SBQQ__Quote__c q = CPQ_TestFactory.createQuote(a.Id, o.Id);
        Id quoteId = q.Id;
        // Product
        Product2 p = [SELECT Id FROM Product2 LIMIT 1];
        // Pricebook
        Pricebook2 pb = [SELECT Id FROM Pricebook2 LIMIT 1];
        // Pricebook Entry
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        test.startTest();
        // Read Quote
        CPQ_API_Helper.QuoteModel quote = CPQ_API_Helper.read(quoteId);
        // Validate Quote
        List<String> qValidate = CPQ_API_Helper.validate(quote);
        // Save Quote
        CPQ_API_Helper.QuoteModel qSave = CPQ_API_Helper.save(quote);
        // Calculate Quote
        CPQ_API_Helper.calculate(quote, 'CPQ_API_QuoteCallBack');
        // Load Product
        CPQ_API_Helper.ProductModel pRead = CPQ_API_Helper.read(p.Id, pb.Id, 'USD');
        // Load Products to the Product Modal - Used for loading bundle products on to a quote
        CPQ_API_Helper.ProductModel pLoad = CPQ_API_Helper.load(p.Id, quote, pRead);
        // Add Products to the quote model
        List<CPQ_API_Helper.ProductModel> pList = new List<CPQ_API_Helper.ProductModel>();
        pList.add(pRead);
        CPQ_API_Helper.QuoteModel qAdd = CPQ_API_Helper.add(quote, pList, 100);
        test.stopTest();
    }
    
    @isTest static void productModelTest() {
        String productModelJson = '{' +
            '"record": {' +
            '"attributes": {' +
            '"type": "Product2",' +
            '"url": "/services/data/v52.0/sobjects/Product2/01t0q000000gaO9AAI"' +
            '},' +
            '"Id": "01t0q000000gaO9AAI",' +
            /* '"CurrencyIsoCode": "USD",' + */
            '"Name": "API - Overage",' +
            '"ProductCode": "API - Overage",' +
            '"Description": "atg",' +
            '"SBQQ__SubscriptionPricing__c": "Fixed Price",' +
            '"SBQQ__PriceEditable__c": false,' +
            '"SBQQ__DefaultQuantity__c": 1.00000,' +
            '"SBQQ__QuantityEditable__c": true,' +
            '"SBQQ__CostEditable__c": false,' +
            '"SBQQ__NonDiscountable__c": false,' +
            '"SBQQ__NonPartnerDiscountable__c": false,' +
            '"SBQQ__SubscriptionTerm__c": 1,' +
            '"SBQQ__PricingMethod__c": "List",' +
            '"SBQQ__PricingMethodEditable__c": true,' +
            '"SBQQ__OptionSelectionMethod__c": "Click",' +
            '"SBQQ__Optional__c": false,' +
            '"SBQQ__Taxable__c": false,' +
            '"SBQQ__CustomConfigurationRequired__c": false,' +
            '"SBQQ__Hidden__c": false,' +
            '"SBQQ__ReconfigurationDisabled__c": false,' +
            '"SBQQ__ExcludeFromOpportunity__c": true,' +
            '"SBQQ__DescriptionLocked__c": false,' +
            '"SBQQ__ExcludeFromMaintenance__c": false,' +
            '"SBQQ__IncludeInMaintenance__c": false,' +
            '"SBQQ__AllocatePotOnOrders__c": false,' +
            '"SBQQ__NewQuoteGroup__c": false,' +
            '"SBQQ__SubscriptionType__c": "Renewable",' +
            '"SBQQ__HasConfigurationAttributes__c": false,' +
            '"SBQQ__ExternallyConfigurable__c": false,' +
            '"SBQQ__BillingFrequency__c": "Monthly",' +
            '"SBQQ__ChargeType__c": "Usage",' +
            '"PricebookEntries": {' +
            '"totalSize": 1,' +
            '"done": true,' +
            '"records": [' +
                '{' +
                    '"attributes": {' +
                    '"type": "PricebookEntry",' +
                    '"url": "/services/data/v42.0/sobjects/PricebookEntry/01u0q000001jwBjAAI"' +
                '},' +
                    '"Product2Id": "01t0q000000gaO9AAI",' +
                    '"Id": "01u0q000001jwBjAAI",' +
                    '"Pricebook2Id": "01s0q000000CbjqAAC",' +
                    '"UnitPrice": 0.08,' +
                    '"IsActive": true' +
                    /* disable if multi currency is not enabled 
                    '"CurrencyIsoCode": "USD"' + */
                '}' +
            ']' +
            '}' +
        '},' +
        '"options": [],' +
        '"features": [],' +
        '"featureCategoryLabels": {' +
            '"Reporting": "Reporting",' +
            '"Implementation": "Implementation",' +
            '"Software": "Software",' +
            '"Hardware": "Hardware"' +
        '},' +
        '"featureCategories": [],' +
        '"currencySymbol": "USD",' +
        '"currencyCode": "USD",' +
        '"constraints": [],' +
        '"configurationAttributes": []' +
        '}';

        CPQ_API_Helper.ProductModel productModel = (CPQ_API_Helper.ProductModel) JSON.deserialize(productModelJson, CPQ_API_Helper.ProductModel.class);
        System.assertEquals(productModel.record.Name, 'API - Overage');
        System.assertEquals(productModel.upgradedAssetId, null);
        System.assertEquals(productModel.currencySymbol, 'USD');
        System.assertEquals(productModel.currencyCode, 'USD');
        System.assertEquals(productModel.featureCategories, new String[]{});
        System.assertEquals(productModel.options, new CPQ_API_Helper.OptionModel[]{});
        System.assertEquals(productModel.features, new CPQ_API_Helper.FeatureModel[]{});
        System.assertEquals(productModel.configuration, null);
        System.assertEquals(productModel.configurationAttributes, new CPQ_API_Helper.ConfigAttributeModel[]{});
        System.assertEquals(productModel.inheritedConfigurationAttributes, null);
    }
}