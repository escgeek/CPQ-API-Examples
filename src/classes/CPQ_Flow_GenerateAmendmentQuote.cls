public class CPQ_Flow_GenerateAmendmentQuote {

    @InvocableMethod (
        label='Generate Amendment Quote' 
        description='Used to create a new quote on an existing opportunity' 
        category='Quote'
    )
    public static List<Results> generateAmendmentQuote(List<Request> requests) {
        // Variables
        String errorMessage; // Used to store any DML error messages that can be displayed to the user in the Flow UI
        List<Results> returnResults = new List<Results>(); // List of Result records that will get passed back to the flow - this will never be more than 1
        List<Opportunity> deleteOpportunities = new List<Opportunity>();
        List<SBQQ__Quote__c> updateQuotes = new List<SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> quoteUpdateMap = new Map<Id, SBQQ__Quote__c>(); // Lists of Quotes to update
        for(Request r : requests) {
            // Create return record
            Results newResult = new Results(); // Result record to set the quote id and return as part of the result list - This ensures the number of returns matches the number of requests
            // Generate the Amendment Opportunity and Quote
            CPQ_API_Helper.QuoteModel quote = CPQ_API_Helper.amendContract(r.contractId);
            // Delete Opportunity create by the amendment cpq api
            Id deleteOpportunityId = quote.record.SBQQ__Opportunity2__c; // Opportunity Reparent
            deleteOpportunities.add(new Opportunity(Id = deleteOpportunityId));
            // Update the Amendment Quote with the existing Opportunity Id
            Id quoteId = (Id) quote.record.get('Id'); // New Amendment Quote Id
            createQuoteUpdate(quoteId, r.opportunityId, quoteUpdateMap);
            checkPrimaryQuotes(quoteId, r.opportunityId, quoteUpdateMap);
            // Set the return Quote Id
            newResult.quoteId = quoteId;
            returnResults.add(newResult);
        }
        CPQ_UtilityClass.safeDML(quoteUpdateMap.values(), 'update', 'SBQQ__Quote__c', 'CPQ_Flow_GenerateAmendmentQuote.generateAmendmentQuote', 'Update the Quote to Primary to force recalc',true); // Records, DML Type, Method Name, Description, CPQ Triggers Enabled/Disabled
        CPQ_UtilityClass.safeDML(deleteOpportunities, 'delete', 'Opportunity', 'CPQ_Flow_GenerateAmendmentQuote.generateAmendmentQuote', 'Delete orphaned opportunities',true); // Records, DML Type, Method Name, Description, CPQ Triggers Enabled/Disabled
        checkErrors(returnResults); // Add error message(s) to the return results if any exists
        // Return Results list - in the flow this list will show up as one record
        return returnResults;
    }

    public static void createQuoteUpdate(Id quoteId, Id opportunityId, Map<Id, SBQQ__Quote__c> quoteUpdateMap){
        quoteUpdateMap.put(quoteId, new SBQQ__Quote__c(
            Id = quoteId,
            SBQQ__Primary__c = true,
            SBQQ__Opportunity2__c = opportunityId, // Reparent New Quote to Existing Opportunity 
            Flow_Created_Source__c = 'CPQ_Flow_GenerateAmendmentQuote'
        ));
    }

    public static void checkPrimaryQuotes(Id quoteId, Id opportunityId, Map<Id, SBQQ__Quote__c> quoteUpdateMap){
        // Method used to unset all other primary quotes - system should do this but sometimes...and 2 primary quotes really messes things up
        for(SBQQ__Quote__c q : [SELECT Id 
                                FROM SBQQ__Quote__c 
                                WHERE SBQQ__Opportunity2__c = :opportunityId 
                                AND Id != :quoteId 
                                AND SBQQ__Primary__c = true])
        {
            quoteUpdateMap.put(q.Id, new SBQQ__Quote__c(
                Id = q.Id,
                SBQQ__Primary__c = false
            ));
        }
    }

    public static void checkErrors(List<Results> returnResults){
        String errorMessage; // Used to store any DML error messages that can be displayed to the user in the Flow UI
        // Check for DML errors to be passed to the flow
        for(String s : CPQ_UtilityClass.errorMessages){
            errorMessage = (errorMessage == null) ? s : errorMessage + ' - ' + s; // Concatenate the error messages in to one string that can be displayed back to the user in the flow UI
        }
        for(Results res : returnResults){
            res.errorMessageString = errorMessage; 
        }
    }

    public class Request{
        @InvocableVariable(label='Opportunity Id' required=true)
        public Id opportunityId;

        @InvocableVariable(label='Contract Id' required=true)
        public Id contractId;
    }

    public class Results {
        @InvocableVariable(label='Quote Id' required=true)
        public String quoteId;

        @InvocableVariable(label='Error Messages' required=false)
        public String errorMessageString;
    }

}