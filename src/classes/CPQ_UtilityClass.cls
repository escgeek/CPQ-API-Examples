/*------------------------------------------------------------------------+
Author: Eric Clay (escgeek@gmail.com)

History: This class started as a way to do two things: catch errors and 
prevent trigger recursion. Over the years and different projects I have
improved on the methods sometimes using other examples for the basis for
the work here and also added different methods based on need to do some 
additional things like send emails after batch jobs complete and so on.

Methods

safeDML - Method that inserts, updates, upserts, and deletes records
with support for disabling CPQ Triggers and using the updatePending 
variable to prevent recursiveness/triggers from refiring again as needed. 
Also logs all errors to an 'Errors__c' custom object for additional tracking
and debugging. Previously this method was called 'safeUpdate' but I renamed 
method since it does more than just update.

2019-05-19 - First Iteration
2022-09-22 - Updates for publishing out to Github

Test Class: CPQ_UtilityClassTest

------------------------------------------------------------------------+*/
public class CPQ_UtilityClass {

    public static Boolean updatesPending = false;

    public static List<String> errorMessages;

    public static void safeDML(list<sObject> records, String dmlType, String objectName, String methodName, String errorMessage, Boolean disableCPQTriggers){
        // Environment switches
        updatesPending = true; // Prevents triggers that have the 'CPQ_UtilityClass.updatesPending' check from refiring
        toggleCPQTriggers(disableCPQTriggers); // CPQ Support - Triggers Toggle On/Off - Uncommend to add 
        // Variables
        dmlType = (dmlType != null) ? dmlType.toUpperCase() : null;
        if(records.size() > 0){
            // Logic
            system.debug('[DML ' + dmlType + ' Action][' + records.size() + '] - ' + errorMessage + ': ' + records);
            switch on dmlType {
                when 'UPDATE'{
                    List<Database.SaveResult> results = Database.update(records, false);
                    handleErrors(JSON.serialize(results), records, objectName, methodName, dmlType.toUpperCase(), errorMessage);
                }
                when 'INSERT'{
                    List<Database.SaveResult> results = Database.insert(records,false);
                    handleErrors(JSON.serialize(results), records, objectName, methodName, dmlType.toUpperCase(), errorMessage);
                }
                when 'UPSERT'{
                    List<Database.UpsertResult> results = Database.upsert(records,false);
                    handleErrors(JSON.serialize(results), records, objectName, methodName, dmlType.toUpperCase(), errorMessage);
                }
                when 'DELETE'{
                    List<Database.DeleteResult> results = Database.delete(records,false);
                    handleErrors(JSON.serialize(results), records, objectName, methodName, dmlType.toUpperCase(), errorMessage);
                }
            }
        }
        toggleCPQTriggers(disableCPQTriggers); // CPQ Support - Triggers Toggle On/Off - Uncommend to add 
        updatesPending = false;
    }

    // CPQ Support - Triggers Toggle On/Off - Uncommend to add 
    public static void toggleCPQTriggers(Boolean disableCPQTriggers){
        // Toggle CPQ Triggers for updates that do not require CPQ automation
        if(disableCPQTriggers){
            if(SBQQ.TriggerControl.isEnabled()){
                SBQQ.TriggerControl.disable();
            } else {
                SBQQ.TriggerControl.enable();
            }
        }
    }

    /* public static boolean triggerDisabled(string triggerOrClass){
        // Checks to make sure that there is a custom setting named "Trigger FailSafe Switch" and used
        // to manage dynamically disabling classes or methods
        // Example: if(CPQ_UtilityClass.triggerDisabled('CPQ_UtilityClass')) return; // Stops if the Custom Setting 'CPQ_UtilityClass' is 'Disabled' under Custom Setting 'Trigger FailSafe Switch'
        Apex_Failsafe_Switch__mdt quick_Disable = Apex_Failsafe_Switch__mdt.getInstance(triggerOrClass);
        if(quick_Disable != NULL && quick_Disable.Disable__c == true){
            system.debug('[triggerDisabled] Class or Trigger Disabled: ' + triggerOrClass);
            return true;
        }
        else {
            return false;
        }
    } */

    // Error handling method
    public static void handleErrors( 
        String saveResults, 
        List <sObject> records,
        String objectName, 
        String methodName, 
        String dmlType, 
        String shortDesc
    ) {
        errorMessages = (errorMessages == null) ? new List<String>() : errorMessages; // This was added to support returning the error messages back to a Flow screen
        List<Error__c> errors = new List<Error__c>();
        Integer index = 0;
        for(DatabaseResult dml : (list<CPQ_UtilityClass.DatabaseResult>) JSON.deserialize(saveResults, list<CPQ_UtilityClass.DatabaseResult>.class)){
            String recordId = (dmlType != null) ? records.get(index).Id : null;
            if(!dml.success){
                Error e = dml.errors[0];
                System.debug('DatabaseResult: ' + dml + ' Error: ' + e); // This debug message helps when debugging test classes where an error record will not be persisted after the test class finishes
                // The object and destination fields can be changed as needed to work with existing objects
                errors.add(new Error__c (
                    Object__c = objectName,
                    Source__c = methodName, // Would recommend class.method : 'CPQ_UtilityClass.handleErrors'
                    Action__c = dmlType,
                    Error_Description__c = shortDesc,
                    Record_Id__c = recordId,
                    // Error Messages
                    Error_Message__c = e.message?.left(255), 
                    Cause__c = e.statusCode,
                    Raw_Error_Message__c = String.valueOf(dml)?.left(255)
                ));
                errorMessages.add(e.message); // Flow Error Support
            }
            ++index;
        }
        safeDML(errors, 'Insert', 'Error__c', 'CPQ_UtilityClass.handleErrors', 'Oops...our error handler threw an error!',false);
    }

    // Error handling method - generic single error
    public static void handleGenericError( 
        String objectName, 
        String methodName, 
        String shortDesc,
        String statusCode,
        String errorMsg,
        String actionType,
        String recordId
    ){
        Insert new Error__c(
            Object__c = objectName,
            Source__c = methodName, // Would recommend class.method : 'CPQ_UtilityClass.handleErrors'
            Action__c = actionType, // Would recommend what type of action caused this error if not a DML action
            Error_Description__c = shortDesc,
            Record_Id__c = recordId,
            // Error Messages
            Error_Message__c = errorMsg?.left(255), 
            Cause__c = statusCode,
            Raw_Error_Message__c = errorMsg?.left(255)
        );
    }

    // Error handling object
    public class DatabaseResult {
        public Id id;
        public Boolean success;
        public List<Error> errors;
    }
    public class Error {
        public String statusCode;
        public String message;
        public List<String> fields;
    }

}