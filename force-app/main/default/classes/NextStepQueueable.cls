/*
 * NextStepQueueable Class Description:
 * 
 * Implement the Queueable interface to process records asynchronously.
 * This example processes up to 10 accounts at a time.
 * It removes the Next Step from the accounts and related opportunities.
 *  
 * Benefits of using Queueable methods:
 * 
 * 1. Chaining Jobs: Allows for the chaining of jobs, meaning you can add another job to the queue from a running job.
 * 2. Stateful Execution: Supports stateful execution, which allows member variables to retain their values between job invocations.
 * 3. High Concurrency: Processes large sets of data without hitting governor limits.
 * 4. Flexibility: Useful for operations that need more flexibility in execution, especially when there's a possibility of chaining or performing related async operations.
 * 5. Enhanced Integration Capabilities: Useful for making asynchronous callouts to external systems, allowing for more extended processing times.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
 * 
 * Note: The class below contains placeholders for implementing a queueable job to update accounts and opportunities.
 */
public with sharing class NextStepQueueable implements Queueable{

    // Member variable to store the accounts
    private Map<Id,Account> accounts;

    // Constructor to accept the accounts
    public NextStepQueueable(Map<Id,Account> accounts) {
        // Store the accounts in a member variable
        this.accounts = accounts;
    }

    // Method to queue the job
    public static void enqueueJob() {
        // Get 10 accounts with Next Step populated
        Map<Id, Account> accounts = new Map<Id, Account> ([SELECT Id, Next_Step__c FROM Account WHERE Next_Step__c != null LIMIT 10]);
        // If there are any accounts, queue the job using System.enqueueJob
        if(!accounts.isEmpty()) {
            System.debug('Accounts found: ' + accounts.size());
            System.enqueueJob(new NextStepQueueable(accounts));
        }
    }

    /*
     * Update/Uncomment the template code to create a method
     * Method to execute the queueable job
     */
    public void execute (QueueableContext context) {
        System.debug('NextStepQueueable executed!');
        // Get the accounts from the member variable
        List<Account> accsToUpdate = new List<Account>();
        for (Account acc : this.accounts.values()) {
            // Remove the Next Step using the helper method
            removeNextStep(acc);
            accsToUpdate.add(acc);
        }
        // Update the accounts
        update accsToUpdate;

        // Get the opportunities related to the accounts
        List<Opportunity> oppsToUpdate = [SELECT Id, NextStep, AccountId FROM Opportunity WHERE AccountId IN : this.accounts.keySet()];
        for (Opportunity opp : oppsToUpdate) {
            // Remove the Next Step using the helper method
            removeNextStep(opp);
        }
        // Update the opportunities
        update oppsToUpdate;

        // Call the enqueueJob method to queue another job to process more records.
        enqueueJob();
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an opportunity
    private static void removeNextStep(Opportunity opp) {
        opp.NextStep = null;
    }

    // Helper method to remove the Next Step
    // Overloaded method to accept an account
    private static void removeNextStep(Account acc) {
        acc.Next_Step__c = null;
    }
}