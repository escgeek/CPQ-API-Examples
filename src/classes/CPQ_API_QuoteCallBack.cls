global with sharing class CPQ_API_QuoteCallBack implements SBQQ.CalculateCallback {
    global void callback(String quoteJSON){
        System.debug('[CPQ_API_QuoteCallBack] - Amendment Quote Calc finished - Saving: ' + quoteJSON);
        SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', quoteJSON);
    }
}