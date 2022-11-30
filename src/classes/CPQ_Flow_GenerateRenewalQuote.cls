/* 

// How to Manually Test this in Developer Console
List<Contract> contractList = [SELECT Id, EndDate FROM Contract LIMIT 1];
CPQ_Flow_GenerateRenewalQuote.Request r1 = new CPQ_Flow_GenerateRenewalQuote.Request();
r1.masterContractId = contractList[0].Id;
r1.renewalContracts = contractList;
List<CPQ_Flow_GenerateRenewalQuote.Request> requestList = new List<CPQ_Flow_GenerateRenewalQuote.Request>{r1};
CPQ_Flow_GenerateRenewalQuote.generateRenewalQuote(requestList);
*/
public class CPQ_Flow_GenerateRenewalQuote {

    @InvocableMethod (
        label='Generate Renewal Quote' 
        description='Used to add a contract(s) to an existing renewal opportunity' 
        category='Quote'
    )
    public static List<Results> generateRenewalQuote(List<Request> requests) {
        // Variables
        List<CPQ_API_Helper.QuoteModel> renewalQuotes = new List<CPQ_API_Helper.QuoteModel>(); // List of Quotes in JSON format
        List<Results> returnResults = new List<Results>(); // List of Result records that will get passed back to the flow - this will never be more than 1
        Map<Id, MasterContract> masterContractMap = new Map<Id, MasterContract>(); // This is used to store our contract dates used to determine term and contract count
        Map<Id, Date> oppCloseDateMap = new Map<Id, Date>(); // Used to update the Opportunity Close Date if needed
        List<Opportunity> opportunityUpdate = new List<Opportunity>(); // List of Opportunities to update Close Date if needed
        Map<Id, SBQQ__Quote__c> quoteUpdateMap = new Map<Id, SBQQ__Quote__c>(); // Lists of Quotes to update
        // Class called from a flow - there will never be more than one record
        // Note: There is a decision to be made here: One method is to create a loop with another method setting what should only be 1 request record to a variable...
        // ...not sure which is easier to read and understand so going with the loop/bulk method
        for(Request r : requests) {
            // Create return record
            Results newResult = new Results(); // Result record to set the quote id and return as part of the result list - This ensures the number of returns matches the number of requests
            // Set the Key
            Id key = r.masterContractId;
            // Generate the Quotes - API returns a list of quotes
            renewalQuotes.addAll(CPQ_API_Helper.renewContract(key,r.renewalContracts));
            // Determine the contract start, end, and term
            for(Contract c : r.renewalContracts){
                // Determines Master Contract dates and count
                setMasterContract(key, c.EndDate, masterContractMap);
            }
            // Once quote is created we loop through the quotes - there will never be more than 1 record returned
            for(CPQ_API_Helper.QuoteModel quote : renewalQuotes){
                Id quoteId = (Id) quote.record.get('Id'); // Quote Id
                Id opportunityId = (Id) quote.record.get('SBQQ__Opportunity2__c');
                createQuoteUpdate(quoteId, key, opportunityId, masterContractMap, quoteUpdateMap, oppCloseDateMap);
                checkPrimaryQuotes(quoteId, opportunityId, quoteUpdateMap);
                createOpportunityUpdate(oppCloseDateMap, opportunityUpdate, key); // Create an Opportunity record if the Closed Date needs updating
                // Set the return Quote Id
                newResult.quoteId = quoteId;
            }
            returnResults.add(newResult);
        }
        // Update the Opportunity if the Close date needs to be updated
        CPQ_UtilityClass.safeDML(opportunityUpdate, 'update', 'Opportunity', 'CPQ_Flow_GenerateRenewalQuote.generateCombinedRenewalQuote', 'Update the Opportunity Close Date', true); // Records, DML Type, Method Name, Description, CPQ Triggers Enabled/Disabled
        // Update the quote with the correct dates and attributes for Combined Renewals
        CPQ_UtilityClass.safeDML(quoteUpdateMap.values(), 'update', 'SBQQ__Quote__c', 'CPQ_Flow_GenerateRenewalQuote.generateCombinedRenewalQuote', 'Update the Quote', false); // Records, DML Type, Method Name, Description, CPQ Triggers Enabled/Disabled
        checkErrors(returnResults); // Add error message(s) to the return results if any exists
        // Return Results list - in the flow this list will show up as one record
        return returnResults;
    }

    public static void setMasterContract(Id key, Date contractEndDate,  Map<Id, MasterContract> masterContractMap){
        // Method used to determine earliest and latest end dates used for determining the contract term and counting the number of associated contracts
        MasterContract mc = new MasterContract();
        if(masterContractMap.containsKey(key)){
            // Looking for the earliest renewal start date which would be the earliest end date
            mc = masterContractMap.get(key);
            if(contractEndDate < mc.EarliestStartDate){
                mc.EarliestStartDate = contractEndDate;
            }
            else if(contractEndDate > mc.LatestStartDate){
                mc.LatestStartDate = contractEndDate;
            }
            mc.contractCount += 1;
            masterContractMap.put(key, mc);
        }
        else{
            mc.EarliestStartDate = contractEndDate;
            mc.LatestStartDate = contractEndDate;
            mc.contractCount = 1;
            mc.recordKey = key;
            masterContractMap.put(key, mc);
        }
        System.debug('MasterContract: ' + mc);
    }

    public static void createQuoteUpdate(Id quoteId, Id key, Id opportunityId, Map<Id, MasterContract> masterContractMap, Map<Id, SBQQ__Quote__c> quoteUpdateMap, Map<Id, Date> oppCloseDateMap){
        // Method used to update the Quote with the appropriate start/end/term values as well as some additional custom details to help track and report on quotes generated from this process
        if(masterContractMap.containsKey(key)){
            MasterContract mc = masterContractMap.get(key);
            Integer term = setTerm(mc.EarliestStartDate, mc.LatestStartDate); // Determines the Contract Term
            Date startDate = mc.EarliestStartDate != null ? mc.EarliestStartDate.addDays(1) : null; // Creates the start date based on the earliest end date
            Date endDate = startDate != null && term != null ? startDate.addMonths(term).addDays(-1) : null; // Creates the end date for all contracts based on the start date plus term minus one day
            quoteUpdateMap.put(quoteId, new SBQQ__Quote__c(
                Id = quoteId,
                SBQQ__Primary__c = true,
                SBQQ__StartDate__c = startDate,
                SBQQ__EndDate__c = endDate,
                SBQQ__RenewalTerm__c = term,
                SBQQ__SubscriptionTerm__c = term,
                // Custom Fields
                Flow_Created__c = true,
                Flow_Created_Source__c = 'CPQ_Flow_GenerateRenewalQuote',
                Merged_Contracts_Count__c = mc.contractCount,
                Merged_Contracts_Quote__c = true
            ));
            // Add Opportunity to Map in order to check that the close date does not need to be updated
            setOpportunityMap(mc.EarliestStartDate, opportunityId, oppCloseDateMap);
        }
    }

    public static void createOpportunityUpdate(Map<Id, Date> oppCloseDateMap, List<Opportunity> opportunityUpdate, Id masterContractId){
        // Method that uses SOQL to validate that a close date change is needed and an Opportunity update is necessary
        for(Opportunity o : [SELECT Id, CloseDate, SBQQ__RenewedContract__c 
                            FROM Opportunity 
                            WHERE Id = :oppCloseDateMap.keySet()])
        {
            Date newCloseDate = oppCloseDateMap.get(o.Id);
            if(newCloseDate != o.CloseDate || o.SBQQ__RenewedContract__c != masterContractId){
                opportunityUpdate.add(new Opportunity(
                    Id = o.Id,
                    CloseDate = newCloseDate,
                    SBQQ__RenewedContract__c = masterContractId
                ));
            }
        }
    }

    public static void setOpportunityMap(Date closeDate, Id opportunityId, Map<Id, Date> oppCloseDateMap){
        // Method used to set the Opportunity Close Date should match the earliest start date
        if(closeDate != null && opportunityId != null){
            oppCloseDateMap.put(opportunityId, closeDate);
        }
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

    public static Integer setTerm(Date earliestStart, Date latestStart){
        // Utility Method
        // Uses the earliest and latest renewal start date to determine the contract term that will cover all segments being combined
        // If less then 12, we assume 12
        // Mod returns the remainder of a number using the second number as the divisor which in this example/usage is 12. 
        // Example: If Jan 1 2025 is the earliest and July 1 2026 is the latest, the different between those 2 dates is 18 so 
        // the mod is 6 so we assume we will need another term.
        Integer term = earliestStart.monthsBetween(latestStart); // Number of months between the earliest and latest start dates
        System.debug('setTerm - earliestStart: ' + earliestStart + ' - latestStart: ' + latestStart + ' - term: ' + term);
        if(term < 12){
            System.debug('setTerm - Difference less than 12 - Defaulting to 12 - Difference: ' + term);
            term = 12;
        }
        else{ 
            Integer bump = math.mod(term, 12); // Determines if the difference divides by 12 without a remainder
            Integer yearsCount = term/12; // Create years for easy math
            Integer dayOverlap = earliestStart.day() < latestStart.day() ? 1 : 0; // If the Earliest Start Date is earlier than the Latest you will need an extra year
            Integer extraYear = bump != 0 ? 1 : 0; // Determines if the term needs to be bumped out 12 months to cover the month offset
            term = (yearsCount + extraYear + dayOverlap) * 12; // Converts the term back to months and adjusts for additional terms based on the date logic
            System.debug('setTerm - term: ' + term + ' - bump: ' + bump + ' - yearsCount: ' + yearsCount + ' - dayOverlap: ' + dayOverlap + ' - extraYear: ' + extraYear);
        }
        return term;
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

    public class MasterContract{
        // Object used to determine the quote start/end dates and term
        public Id recordKey;
        public Date EarliestStartDate;
        public Date LatestStartDate;
        public Integer contractCount;
    }

    public class Request{
        @InvocableVariable(label='Renewal Contracts' required=true)
        public List<Contract> renewalContracts;

        @InvocableVariable(label='Master Contract Id' required=true)
        public Id masterContractId;
    }

    public class Results {
        @InvocableVariable(label='Quote Id' required=true)
        public String quoteId;

        @InvocableVariable(label='Error Messages' required=false)
        public String errorMessageString;
    }
}