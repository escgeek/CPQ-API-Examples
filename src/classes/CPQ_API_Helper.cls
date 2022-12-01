public class CPQ_API_Helper {

    // Read Quote
    public static QuoteModel read(String quoteId) {
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quoteId);
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    // Validate Quote
    public static List<String> validate(QuoteModel quote) {
        String res = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteValidator', null, JSON.serialize(quote));
        return (List<String>) JSON.deserialize(res, List<String>.class);
    }

    // Save Quote
    public static QuoteModel save(QuoteModel quote) {
        String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quote));
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    // Calculate Quote
    public static void calculate(QuoteModel quote, String callbackClass) {
        QuoteCalculatorContext ctx = new QuoteCalculatorContext(quote, callbackClass);
        SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteCalculator', null, JSON.serialize(ctx));    
    }

    // Read/Load Products to the Product Modal - Used for adding simple product or products to a quote
    public static ProductModel read(Id productId, Id pricebookId, String currencyCode) {
        ProductReaderContext ctx = new ProductReaderContext(pricebookId, currencyCode);
        String productJSON = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', productId, JSON.serialize(ctx));
        return (ProductModel) JSON.deserialize(productJSON, ProductModel.class);
    }

    // Load Products to the Product Modal - Used for loading bundle products on to a quote
    public static ProductModel load(Id productId, QuoteModel quote, ProductModel parentProduct) {
        ConfigLoadContext ctx = new ConfigLoadContext(quote, parentProduct);
        String productJSON = SBQQ.ServiceRouter.load('SBQQ.ConfigAPI.ConfigLoader', productId, JSON.serialize(ctx));
        return (ProductModel) JSON.deserialize(productJSON, ProductModel.class);
    }
    
    // Add Products to the quote model
    public static QuoteModel add(QuoteModel quote, ProductModel[] products, Integer groupKey) {
        AddProductsContext ctx = new AddProductsContext(quote, products, groupKey);
        String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, JSON.serialize(ctx));
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    // Contract Amendment
    public static QuoteModel amendContract(String contractId) {
        String quoteJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractAmender', contractId, null);
        return (QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class);
    }

    // Contract Renewal
    public static List<QuoteModel> renewContract(Id contractId) {
        Contract contract = new Contract(Id = contractId);
        return renewContract(contract);
    }
    
    public static List<QuoteModel> renewContract(Contract contract) {
        return renewContract(contract.Id, new List<Contract>{contract});
    }

    public static List<QuoteModel> renewContract(Id contractId, List<Contract> contracts) {
        RenewalContext contractPayload = new RenewalContext(); // Create the Payload
        contractPayload.renewedContracts = contracts; // Set the Renewal Contracts
        // This creates the list of contract renewals using the CPQ API callout
        String quotesJSON = SBQQ.ServiceRouter.load('SBQQ.ContractManipulationAPI.ContractRenewer', (String) contractId, JSON.serialize(contractPayload));
        // Return the list of quotes - usually only 1
        return (List<QuoteModel>) System.JSON.deserialize(quotesJSON, LIST<QuoteModel>.class);
    }

    // Data Model
    public class QuoteModel {
        public SBQQ__Quote__c record;
        public QuoteLineModel[] lineItems;
        public QuoteLineGroupModel[] lineItemGroups;
        public Integer nextKey;
        public Boolean applyAdditionalDiscountLast;
        public Boolean applyPartnerDiscountFirst;
        public Boolean channelDiscountsOffList;
        public Decimal customerTotal;
        public Decimal netTotal;
        public Decimal netNonSegmentTotal;
    }
    
    public class QuoteCalculatorContext {        
        public QuoteModel quote;
        public String callbackClass;
    
        public QuoteCalculatorContext(QuoteModel quote, String callbackClass) {
            this.quote = quote;            
            this.callbackClass = callbackClass;        
        }
    } 

    public class QuoteLineModel {
        public SBQQ__QuoteLine__c record;
        public Boolean amountDiscountProrated;
        public Integer parentGroupKey;
        public Integer parentItemKey;
        public Integer key;
        public Boolean upliftable;
        public String configurationType;
        public String configurationEvent;
        public Boolean reconfigurationDisabled;
        public Boolean descriptionLocked;
        public Boolean productQuantityEditable;
        public Decimal productQuantityScale;
        public String dimensionType;
        public Boolean productHasDimensions;
        public Decimal targetCustomerAmount;
        public Decimal targetCustomerTotal;
    }

    public class QuoteLineGroupModel {
        public SBQQ__QuoteLineGroup__c record;
        public Decimal netNonSegmentTotal;
        public Integer key;
    }

    public class OptionModel { 
        public SBQQ__ProductOption__c record; 
        public Map<String,String> externalConfigurationData; 
        public Boolean configurable; 
        public Boolean configurationRequired; 
        public Boolean quantityEditable; 
        public Boolean priceEditable; 
        public Decimal productQuantityScale; 
        public Boolean priorOptionExists; 
        public Set<Id> dependentIds; 
        public Map<String,Set<Id>> controllingGroups; 
        public Map<String,Set<Id>> exclusionGroups; 
        public String reconfigureDimensionWarning; 
        public Boolean hasDimension; 
        public Boolean isUpgrade; 
        public String dynamicOptionKey; 
    }

    public class FeatureModel { 
        public SBQQ__ProductFeature__c record; 
        public String instructionsText; 
        public Boolean containsUpgrades; 
    }

    public class ConfigAttributeModel { 
        public String name; 
        public String targetFieldName; 
        public Decimal displayOrder; 
        public String colmnOrder;
        public Boolean required;
        public Id featureId;
        public String position;
        public Boolean appliedImmediately;
        public Boolean applyToProductOptions;
        public Boolean autoSelect;
        public String[] shownValues;
        public String[] hiddenValues;
        public Boolean hidden;
        public String noSuchFieldName;
        public Id myId;
    }

    public class ConfigurationModel { 
        public Id configuredProductId; 
        public Id optionId; 
        public SBQQ__ProductOption__c optionData;
        public SBQQ__ProductOption__c configurationData; 
        public SBQQ__ProductOption__c inheritedConfigurationData; 
        public ConfigurationModel[] optionConfigurations; 
        public Boolean configured; 
        public Boolean changedByProductActions; 
        public Boolean isDynamicOption; 
        public Boolean isUpgrade; 
        public Set<Id> disabledOptionIds; 
        public Set<Id> hiddenOptionIds; 
        public Decimal listPrice; 
        public Boolean priceEditable; 
        public String[] validationMessages; 
        public String dynamicOptionKey; 
    }

    public class ConstraintModel { 
        public SBQQ__OptionConstraint__c record; 
        public Boolean priorOptionExists; 
    }

    public class ProductModel {
        public Product2 record;
        public Id upgradedAssetId;
        public String currencySymbol;
        public String currencyCode;
        public String[] featureCategories;
        public OptionModel[] options;
        public FeatureModel[] features;
        public ConfigurationModel configuration;
        public ConfigAttributeModel[] configurationAttributes;
        public ConfigAttributeModel[] inheritedConfigurationAttributes;
        public ConstraintModel[] constraints; 
    }

    public class QuoteProposalModel {
        public String name;
        public Id quoteId;
        public Id templateId;
        public String language;
        public String outputFormat;
        public String paperSize;
    }

    public class QuoteTermModel {
        public String value;
        public String type;
        public Id standardTermId;
        public Id quoteId;
        public Boolean locked;
        public String label;
        public Id id;
    }

    private class ProductReaderContext {
        private Id pricebookId;
        private String currencyCode;
        
        private ProductReaderContext(Id pricebookId, String currencyCode) {
            this.pricebookId = pricebookId;
            this.currencyCode = currencyCode;
        }
    }
 
    private class ConfigLoadContext {
        private QuoteModel quote;
        private ProductModel parentProduct;
    
        private ConfigLoadContext(QuoteModel quote, ProductModel parentProduct) {
            this.quote = quote;
            this.parentProduct = parentProduct;
        }
    }

    private class AddProductsContext {
        private QuoteModel quote;
        private ProductModel[] products;
        private Integer groupKey;
        private final Boolean ignoreCalculate = true;
    
        private AddProductsContext(QuoteModel quote, ProductModel[] products, Integer groupKey) {
            this.quote = quote;
            this.products = products;
            this.groupKey = groupKey;
        }
    }

    public class RenewalContext {
        public Id masterContractId;
        public List<Contract> renewedContracts;
        public Boolean returnOnlyQuoteId;
    }
}