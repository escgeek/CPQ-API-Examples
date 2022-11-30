@isTest
public class CPQ_UtilityClassTest {

    @isTest
    public static void testUtilityClass(){

        test.startTest();

        // Create Record
        Account a = CPQ_TestFactory.createAccount();
        List<Account> accountList = new List<Account>{a};
        
        // Insert Record
        CPQ_UtilityClass.safeDML(accountList, 'Insert', 'Account', 'Test Method', 'Account', false);
        
        // Update Record - Will throw an error
        CPQ_UtilityClass.safeDML(accountList, 'Update', 'Account', 'Test Method', 'Account', false);
        // Throws 1 error
        a.Name = '========================================================================================================String longer than 255 characters=======================================================================================================================';
        
        // Upsert Record
        CPQ_UtilityClass.safeDML(accountList, 'Upsert', 'Account', 'Test Method', 'Account', false);
        
        // Delete Record
        CPQ_UtilityClass.safeDML(accountList, 'Delete', 'Account', 'Test Method', 'Account', false);

        // Test the CPQ Trigger Disable
        CPQ_UtilityClass.toggleCPQTriggers(true); // Toggles off
        CPQ_UtilityClass.toggleCPQTriggers(true); // Toggles back on

        test.stopTest();

        // Created, updated, deleted. Should be zero (0)
        Integer accountCount = [SELECT count() FROM Account];
        // Error count should be 1 from the upsert
        //Integer errorCount = [SELECT count() FROM Error__c];

        System.assertEquals(0, accountCount, 'Should be zero accounts after creating, updating, and then deleting Account record');
        //System.assertEquals(1, errorCount, 'Should have thrown 1 error and created 1 error record');

    }  

    /* @isTest
    static void testTriggerDisabled(){

        test.startTest();
        // Positive Test
        Boolean testTrue = CPQ_UtilityClass.triggerDisabled('Test');
        System.assertEquals(testTrue, true, 'Should return true since the record exists');
        
        // Negative Test
        Boolean testFalse = CPQ_UtilityClass.triggerDisabled('Test does not exist');
        System.assertEquals(testFalse, false, 'Should return false since the record does not exist');
        test.stopTest();
    } */

    @isTest
    public static void testErrorMethods(){
        CPQ_UtilityClass.handleGenericError(
            'Account',
            'accountClass.newAccount',
            'Account Class',
            'Issue Failed',
            'Test Failed',
            'Insert',
            'a0qDn000000ZPWwIAO'
        );
    }
}