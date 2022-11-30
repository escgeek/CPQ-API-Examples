# CPQ-API-Examples

This git repository project started out as a simple exercise in knowledge sharing but as I have built out what I thought would be a couple of simple examples involving how to use the CPQ API to generate renewals and amendment quotes quick grew in size and scope to includes the following:

- CPQ API Model and Method Class in 1 file (except the callback which is in its own file)
- Amendment and Renewal examples that includes apex and flows
- Aura Flow Component used to redirect the flow to a url, in this case the quote editor
- TestData class used to generate account, opportunity, quote, quote lines and quote groups for testing
- TestFactory class used for the test classes 
- Utility Class to manage DML 
- Test classes to support these examples all with 100% coverage

I thought I could stop at the first 2 bullets but boy was I wrong! This quickly became a house of cards of dependent utilities and classes required to keep this simple.

**Quick Introduction to CPQ API**

When you get started with trying to use the CPQ API and take a look at Salesforce Help and other resources for direction and documentation on the web you find that there is just not a lot of examples or tutorials out there to help accomplish what I consider common business use cases. And in addition to trying to share examples I also wanted to pass on some tips and tricks for stuff to watch out for as with every instance there is always a different mix in the amount of automations at play and considerations for how it plays or doesn't play well with CPQ API call-outs. 

**Prerequisites - Installing/Creating the CPQ API Model and Method Classes**

To get started we will first review the pre-req's for your Salesforce Org and then review some code examples for how to do things such as amendments and renewals.

And before getting started I would like to acknowledge that this example borrows heavily on the ideas and examples that Austin Turner published on github many many years ago. Big thanks as I have used these for a long time and was a great starting point for my owner version.

- [Austin's github gist's](https://gist.github.com/paustint)

- [CPQ API Gist](https://gist.github.com/paustint/40b602503b6cd6ae879af7b85d910da8)

The first step before you can create a flow or invokable apex classes is to make sure that you have all of the supporting CPQ API methods and data models defined in your Salesforce org. Traditional you can do this by reviewing the Salesforce Help and using example classes. The only problem with that is the examples all suggest creating separate files for each data model and api method. This approach generates a lot of classes and though I've seen lots of orgs do just that there's a more simple way of accomplish this: Combine all of the data models and api methods in to one apex class so that you have 1 class for the methods/models and 1 class for the test coverage. 

- [Example CPQ API Methods and Data Model class](src/classes/CPQ_API_Helper.cls)

Here are the reference links to the Salesforce Help source below for reference. Use this for reference and for command reference:

- [CPQ API Data Model Classes](https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_api.meta/cpq_dev_api/cpq_api_models.htm)

- [Base API Methods (Read/Load/Save/etc.)](https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_api.meta/cpq_dev_api/cpq_api_pricing_parent.htm)

- [Renewal/Amendment Methods](https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_api.meta/cpq_dev_api/cpq_api_contract_parent.htm)

**Background**

So why re-create the wheel when Austin's version works? Well...this basically started out as a troubleshooting step as I was on a project using a modified version of the CPQ_ApiWrapper and CPQ_ApiModel classes when I ran in to an issue that I just could not get around. One thing to note is that I'm a consultant so when I start a new project I'm also starting in a new org so one of the first things I do is to deploy certain tools. So frustration set in after spinning my wheels so as a troubleshooting step I decided to create a fresh new version straight from the Salesforce examples that included both the models and methods in 1 apex class. That fixed the issue and I've been using, updating, and tweaking this version ever since. And there's nothing magically or groundbreaking here,  just trying to pay it forward with an example of how to store all of the models and methods in 1 apex class to minimize the amount of sprawl required to use the CPQ API.

**Generating Renewal Quotes**

I have used the CPQ API to generate quote docs, quote lines, and some other client specific stuff but for these examples we're going to focus on generating renewals and amendments. 

- The CPQ API is looking for 2 things:
	- Master Contract - this should be the contract with the earliest renewal date
	- List of Contracts (see Gotchas)
- What the CPQ API returns is a list of quotes. We will bulk our code for best practices though because this is a flow example you will only get 1 record returned and even if you were doing this processing through batch your batch size would probably still be 1. 
- For multiple renewals you will need to update the quote start date, end date, and/or term depending on requires in order to ensure that the total term of the renewal covers all of the related contracts and subscriptions.

**Gotchas!**
1. If there is an Opportunity already generated and linked in the 'Renewal Opportunity' field on the source contract, the API will just generate a new quote. If it is blank, it generates both. For Amendments, it always generates the Opportunity but you can reparent the Quote which we'll talk about more below in the Amendment section.
2. You will need to check to make sure that the previous primary quote has been set to not primary. The System SHOULD handle this but sometimes does not...better to be safe than sorry as the system does strange things with 2 primary quotes (wrong rollup numbers, products, etc. plus the quote line editor can simple not load).
Multiple Renewal Gotchas!
1. All of the contracts must either have a blank Opportunity or reference the Same Opportunity otherwise the process will fail. This is important. You also cannot generate a quote for just one contract once another contract is referenced by the same renewal opportunity. That's to say if you have 3 contracts all referencing 'Renewal Opp 1' and then you go and try and generate a renewal quote using the checkbox on the contract, it will fail due to the opportunity also being referenced by other contracts. You can blank out that renewal opportunity and generate it then but that presents a bit of a data issue if someone takes the original quote that is linked to this contract and closes and contracts that opportunity.
2. Groups - for multiple renewals it would be recommended to add automation that if the renewal lines are not already grouped that they are grouped by contract so that the possible different terms can be managed at the group level. I would also recommend appending the group names with the source contracts when the groups are created in order to more easily manage the data

**Generating Amendment Quotes**

- The CPQ API is looking for 1 thing:
	- Contract Id
- What the CPQ API returns is a quote model. I usually just pull out the quote id and return that.

**Gotchas!**
- If you are generating this Amendment from the Opportunity, which is what I would recommend, you will need to reparent the new quote to the existing opportunity and delete the new opportunity that was created as part of the CPQ API process. This is located on the quote model and can be pulled just like you pull the quote Id.
- Just like with renewals, you will need to check to make sure that the existing primary quote if it exists is set to not primary. You do not have to make the new quote primary, I have gotten that scenario working, but in this example the new quote is the primary to keep things simple and keep the amount of custom code lower.

**Standard Way of using the CPQ API**
1. Generate the quote
2. Update the Data
3. Save the Quote using the callback service
When you generate the quote, there are a couple of things to keep in mind:
- The data you have in the data model is instantly out of date if you have additional async automation (like async flows) will cause the data that you have to be out of date. do not save this version of the quote as it will overwrite those other saves
- Sometimes using the callback service can also cause errors where just doing a standard DML update will work
- And if you are not updating the data in the data model do not use the callback method, just use a standard DML

**Last things to keep in mind**
- You have to check to make sure that the quote saved and did not error out, this means checking to make sure that quote has a related Opportunity and/or account which are the 2 fields that fail on the second save/quote calc. You can do this in the apex but typically I do it in the flow as I can present a visual error much easier.
- You can pass the error message back to the flow (using my handy dandy dml helper class as an example) so that the error screen you present has the actual system error. Usually a validation rule so seeing that rule can sometimes clue in the user as to what to update or change to get the quote generate and/or at least have something that they can give the support team to help troubleshoot.
- If you are updating the quote via async, make sure those do not kick off until you have done the second save (see example in the code). I usually put a field in the apex quote update that lets any async code know the second and final save has happened otherwise you risk those changes or values getting overwritten. 
