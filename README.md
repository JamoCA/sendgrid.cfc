# sendgrid.cfc
A CFML wrapper for the SendGrid's [Web API v3](https://sendgrid.com/docs/API_Reference/api_v3.html). It currently supports building and sending transactional emails, as well as portions of the API related to marketing emails.

### Acknowledgements

This project borrows heavily from the API frameworks built by [jcberquist](https://github.com/jcberquist), such as [xero-cfml](https://github.com/jcberquist/xero-cfml) and [aws-cfml](https://github.com/jcberquist/aws-cfml). Because it draws on those projects, it is also licensed under the terms of the MIT license.

## Table of Contents

- [Installation](#installation)
  - [Standalone Usage](#standalone-usage)
  - [Use as a ColdBox Module](#use-as-a-coldbox-module)
- [Quick Start for Sending](#quick-start)
- [How to build an email](#how-to-build-an-email)
- [`sendgrid.cfc` Reference Manual](#sendgridcfc-reference-manual)
	- [Mail Send](#mail-send-reference)
  - [Blocks](#blocks-api-reference)
  - [Bounces](#bounces-api-reference)
  - [Campaigns](#campaigns-api-reference)
  - [Contacts API - Recipients](#contacts-api---recipients-reference)
  - [Contacts API - Segments](#contacts-api---segments-reference)
  - [Contacts API - Custom Fields](#contacts-api---custom-fields-reference)
  - [Contacts API - Lists](#contacts-api---lists-reference)
  - [Invalid Emails](#invalid-emails-api-reference)
  - [Sender Identities API](#sender-identities-api-reference)
  - [Suppressions - Suppressions](#suppressions---suppressions-reference)
  - [Suppressions - Unsubscribe Groups](#suppressions---unsubscribe-groups-reference)
  - [Cancel Scheduled Sends](#cancel-scheduled-sends-reference)
  - [Spam Reports](#spam-reports-api-reference)
  - [Validate Email](#validate-email)
- [Reference Manual for `helpers.mail`](#reference-manual-for-helpersmail)
- [Reference Manual for `helpers.campaign`](#reference-manual-for-helperscampaign)
- [Reference Manual for `helpers.sender`](#reference-manual-for-helperssender)
- [Questions](#questions)
- [Contributing](#contributing)

## Installation
This wrapper can be installed as standalone component or as a ColdBox Module. Either approach requires a simple CommandBox command:

```
$ box install sendgridcfc
```

If you can't use CommandBox, all you need to use this wrapper as a standalone component is the `sendgrid.cfc` file and the helper components, located in `/helpers`; add them to your application wherever you store cfcs. But you should really be using CommandBox.

### Standalone Usage

This component will be installed into a directory called `sendgridcfc` in whichever directory you have chosen and can then be instantiated directly like so:

```cfc
sendgrid = new sendgridcfc.sendgrid( apiKey = 'xxx' );
```

### Use as a ColdBox Module

To use the wrapper as a ColdBox Module you will need to pass the configuration settings in from your `config/Coldbox.cfc`. This is done within the `moduleSettings` struct:

```cfc
moduleSettings = {
  sendgridcfc = {
    apiKey = 'xxx'
  }
};
```

You can then leverage the CFC via the injection DSL: `sendgrid@sendgridcfc`; the helper components follow the same pattern:

```
property name="sendgrid" inject="sendgrid@sendgridcfc";
property name="mail" inject="mail@sendgridcfc";
property name="campaign" inject="campaign@sendgridcfc";
property name="sender" inject="sender@sendgridcfc";
```

## Quick Start
The following is a minimal example of sending an email, using the `mail` helper object.

```cfc
sg = new sendgrid( apiKey = 'xxx' );

mail = new helpers.mail()
	.from( 'test@example.com' )
	.subject( 'Sending with SendGrid is Fun' )
	.to( 'test@example.com' )
	.plain( 'and easy to do anywhere, even with ColdFusion');

sg.sendMail( mail );
```

## How to build an email

SendGrid enables you to do a lot with their endpoint for sending emails. This functionality comes with a tradeoff: a more complicated mail object that many other transactional email providers. So, following the example of their official libraries, I've put together a mail helper to make creating and manipulating the mail object easier.

As seen in the Quick Start example, a basic helper can be created via chaining methods:

```cfc
mail = new helpers.mail().from( 'name@youremail.com' ).subject( 'Hi, I love your emails' ).to( 'myfriend@email.com' ).html( '<p>Hi,</p><p>Thanks for all your emails</p>');
```
Alternatively, you can create the basic object with arguments, on init:

```cfc
from = 'name@youremail.com';
subject = 'Hi, I love your emails';
to = 'myfriend@email.com';
content = '<p>Hi,</p><p>Thanks for all your emails</p>';
mail = new helpers.mail( from, subject, to, content );
```
Note that for this API wrapper, the assumption when the `content` argument is passed in to `init()`, is that it is HTML, and that both html and plain text should be set and sent.

The `from`, `subject`, `to`, and message content, whether plain or html, are minimum required fields for sending an email.

I've found two places where the `/mail/send` endpoint JSON body are explained, and the (77!) possible parameters outlined. Familiarizing yourself with these will be of great help when using the API: [V3 Mail Send API Overview](https://sendgrid.com/docs/API_Reference/Web_API_v3/Mail/index.html) and [Mail Send Endpoint Documentation](https://sendgrid.api-docs.io/v3.0/mail-send).

## `sendgrid.cfc` Reference Manual

### Mail Send Reference
*View SendGrid Docs for [Sending Mail](https://sendgrid.com/docs/API_Reference/Web_API_v3/Mail/index.html)*

#### `sendMail( required component mail )`
Sends email, using SendGrid's REST API. The `mail` argument must be an instance of the `helpers.mail` component. See [the quick start for sending](#quick-start) and [how to build an email](#how-to-build-an-email) for more information on how this is used.

---

### Blocks API Reference
*View SendGrid Docs for [Blocks](https://sendgrid.com/docs/API_Reference/Web_API_v3/blocks.htmll)*

#### `listBlocks( any start_time = 0, any end_time = 0, numeric limit = 0, numeric offset = 0 )`
Retrieve a list of all email addresses that are currently on your blocks list. The `start_time` and `end_time` arguments, if numeric, are assumed to be unix timestamps. Otherwise, they are presumed to be a valid date that will be converted to unix timestamps automatically.

#### `getBlock( required string email )`
Retrieve a specific email address from your blocks list.

---

### Bounces API Reference
*View SendGrid Docs for [Bounces](https://sendgrid.com/docs/API_Reference/Web_API_v3/bounces.html)*

#### `listBounces( any start_time = 0, any end_time = 0, numeric limit = 0, numeric offset = 0 )`
Retrieve a list of bounces that are currently on your bounces list. The `start_time` and `end_time` arguments, if numeric, are assumed to be unix timestamps. Otherwise, they are presumed to be a valid date that will be converted to unix timestamps automatically.

#### `getBounce( required string email )`
Retrieve specific bounce information for a given email address.

---

### Campaigns API Reference
*View SendGrid Docs for [Campaigns](https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/campaigns.html)*

#### `createCampaign( required any campaign )`
Allows you to create a marketing campaign. The `campaign` argument should be an instance of the `helpers.campaign` component. However, if you want to create and pass in the struct or json yourself, you can. See [the campaign helper reference manual](#reference-manual-for-helperscampaign) for more information on how this is used.

#### `listCampaigns()`
Retrieve a list of all of your campaigns.

#### `getCampaign( required numeric id )`
Retrieve a single campaign by ID.

#### `deleteCampaign( required numeric id )`
Delete a single campaign by ID.

#### `updateCampaign( required numeric id, required any campaign )`
Update a campaign by ID. The `campaign` arguments should be an instance of the `helpers.campaign` component. However, if you want to create and pass in the struct or json yourself, you can. See [the campaign helper reference manual](#reference-manual-for-helperscampaign) for more information on how this is used.

---

### Contacts API - Recipients Reference
*View SendGrid Docs for [Contacts API - Recipients](https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html#-Recipients)*

#### `addRecipients( required array recipients )`
Add Marketing Campaigns recipients. Note that it also appears to update existing records, so it basically functions like a PATCH. The `recipients` arguments is an array of objects, with at minimum, and 'email' key/value.

#### `addRecipient( required any recipient, string first_name = '', string last_name = '', struct customFields = {} )`
Convenience method for adding a single recipient at a time. The `recipient` arguments facilitates two means of adding a recipient. You can pass in a struct with key/value pairs providing all relevant recipient information. Alternatively, you can use this to simply pass in the recipient's email address, which is all that is required. The `customFields` keys correspond to your custom field names, along with their assigned values.

#### `updateRecipients( required array recipients )`
Update one or more Marketing Campaign recipients. Note that it will also add non-existing records. The `recipients` arguments is an array of objects, with at minimum, and 'email' key/value.

#### `updateRecipient( required any recipient, string first_name = '', string last_name = '', struct customFields = {} )`
Convenience method for updating a single recipient at a time. The `recipient` arguments facilitates two means of adding a recipient. You can pass in a struct with key/value pairs providing all relevant recipient information. Alternatively, you can use this to simply pass in the recipient's email address, which is all that is required. The `customFields` keys correspond to your custom field names, along with their assigned values.

#### `getRecipientUploadStatus()`
Check the upload status of a Marketing Campaigns recipient.

#### `deleteRecipient( required string id )`
Delete a single recipient with the given ID from your contact database. The `id` arguments can be the recipient ID or email address (which will be converted to the recipient ID)

#### `deleteRecipients( required array recipients )`
Deletes one or more recipients. This is an incomplete implementation of the SendGrid API. Technically, this should send a DELETE request to `/contactdb/recipients`, with an array of IDs as the body. But ColdFusion doesn't currently include the request body in DELETE calls. So we loop the recipients through the individual delete method. The `recipients` arguments is an array of the recipient IDs you want to delete. You can also provide their email addresses, and they will be converted to recipient IDs

#### `listRecipients( numeric page = 0, numeric pageSize = 0 )`
Retrieve all of your Marketing Campaign recipients.

#### `getRecipient( required string id )`
Retrieve a single recipient by ID from your contact database. The `id` argument can be the recipient ID or email address (which will be converted to the recipient ID).

#### `listListsByRecipient( required string id )`
Retrieve the lists that a given recipient belongs to. The `id` argument can be the recipient ID or email address (which will be converted to the recipient ID).

#### `getBillableRecipientCount()`
Retrieve the number of Marketing Campaigns recipients that you will be billed for.

#### `getRecipientCount()`
Retrieve the total number of Marketing Campaigns recipients.

#### `searchRecipients( required string fieldName, any search = '' )`
Perform a search on all of your Marketing Campaigns recipients. The `fieldName` argument is the name of a custom field or reserved field. The `search` argument is the value to search for within the specified field. Date fields must be unix timestamps. Currently, searches that are formatted as a U.S. date in the format mm/dd/yyyy (1-2 digit days and months, 1-4 digit years) are converted automatically.

---

### Contacts API - Segments Reference
*View SendGrid Docs for [Contacts API - Segments](https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html#-Segments)*

#### `createSegment( required string name, required array conditions, numeric listId = 0 )`
Create a segment using search conditions.

The `conditions` argument is an array of structs making up the search conditions that define this segment. Read [SendGrid documentation](https://sendgrid.api-docs.io/v3.0/contacts-api-segments/create-a-segment) for specifics on how to segment contacts.

The `listId` argument indicates the list from which to make this segment. Not including this ID will mean your segment is created from the main contactdb rather than a list.

#### `listSegments()`
Retrieve all of your segments.

#### `getSegment( required numeric id )`
Retrieve a single segment with the given ID.

#### `updateSegment( required numeric id, string name = '', array conditions = [], numeric listId = 0 )`
Update a segment. Functions similarly to `createSegment()`, but you only need to include the parameters you are updating.

Note that the `listId` argument can be used to change the list for this segment, but once a list has been set, the segment cannot be returned to the main contactdb.

#### `deleteSegment( required numeric id )`
Delete a segment from your recipients database.

#### `listRecipientsBySegment( required numeric id )`
Retrieve all of the recipients in a segment with the given ID.

---

### Contacts API - Custom Fields Reference
*View SendGrid Docs for [Contacts API - Custom Fields](https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html#-Custom-Fields)*

#### `createCustomField( required string name, required string type )`
Create a custom field. For the `type` arguments, the allowed values are 'text', 'date', and 'number'.

#### `listCustomFields()`
Retrieve all custom fields.

#### `getCustomField( required numeric id )`
Retrieve a custom field by ID.

#### `deleteCustomField( required numeric id )`
Delete a custom field by ID.

#### `listReservedFields()`
List all fields that are reserved and can't be used for custom field names.

---

### Contacts API - Lists Reference
*View SendGrid Docs for [Contacts API - Lists](https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html#-Lists)*

#### `createList( required string name )`
Create a list for your recipients.

#### `listLists()`
Retrieve all of your recipient lists. If you don't have any lists, an empty array will be returned.

#### `deleteLists( required array lists )`
Delete multiple recipient lists. This is an incomplete implementation of the SendGrid API. Technically, this should send a DELETE request to `/contactdb/lists`, with an array of IDs as the body. But ColdFusion doesn't currently include the request body in DELETE calls. So we loop the lists through the individual delete method. The `recipients` argument is an array of the list IDs you want to delete.

#### `deleteList( required numeric id )`
Delete a single list with the given ID from your contact database.

#### `getList( required numeric id )`
Retrieve a single recipient list by ID.

#### `updateList( required numeric id, required string name )`
Update the name of one of your recipient lists.

#### `listRecipientsByList( required numeric id, numeric page = 0, numeric pageSize = 0 )`
Retrieve all recipients on the list with the given ID.

#### `addRecipientToList( required numeric listId, required string recipientId )`
Add a single recipient to a list. The `recipientId` argument can be the recipient ID or email address (which will be converted to the recipient ID).

#### `deleteRecipientFromList( required numeric listId, required string recipientId )`
Delete a single recipient from a list. The `recipientId` argument can be the recipient ID or email address (which will be converted to the recipient ID).

#### `addRecipientsToList( required numeric listId, required array recipients )`
Add multiple recipients to a list. The `recipients` argument is an array of recipient IDs or email addresses. The first element of the array is checked to determine if it is an array of IDs or email addresses.

---

### Invalid Emails API Reference
*View SendGrid Docs for [Invalid Emails](https://sendgrid.com/docs/API_Reference/Web_API_v3/invalid_emails.html)*

#### `listInvalidEmails( any start_time = 0, any end_time = 0, numeric limit = 0, numeric offset = 0 )`
Retrieve a list of invalid emails that are currently on your invalid emails list. The `start_time` and `end_time` arguments, if numeric, are assumed to be unix timestamps. Otherwise, they are presumed to be a valid date that will be converted to unix timestamps automatically.

#### `getInvalidEmail( required string email )`
Retrieve information about a specific invalid email address.

---

### Sender Identities API Reference
*View SendGrid Docs for [Sender Identities](https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/sender_identities.html)*

#### `createSender( required any sender )`
Allows you to create a new sender identity. The `sender` argument should be an instance of the `helpers.sender` component. However, if you want to create and pass in the struct or json yourself, you can. See [the sender helper reference manual](#reference-manual-for-helperssender) for more information on how this is used.

#### `listSenders()`
Retrieve a list of all sender identities that have been created for your account.

#### `updateSender( required numeric id, required any sender )`
Update a sender identity by ID. The `sender` argument should be an instance of the `helpers.sender` component. However, if you want to create and pass in the struct or json yourself, you can. See [the sender helper reference manual](#reference-manual-for-helperssender) for more information on how this is used.

#### `deleteSender( required numeric id )`
Delete a single sender identity by ID.

#### `resendSenderVerification( required numeric id )`
Resend a sender identity verification email.

#### `getSender( required numeric id )`
Retrieve a single sender identity by ID.

---

### Suppressions - Suppressions Reference
*View SendGrid Docs for [Suppressions - Suppressions](https://sendgrid.com/docs/API_Reference/Web_API_v3/Suppression_Management/suppressions.html)*

#### `addEmailsToUnsubscribeGroup( required numeric id, required array emails )`
Add email addresses to an unsubscribe group. If you attempt to add suppressions to a group that has been deleted or does not exist, the suppressions will be added to the global suppressions list.

#### `addEmailToUnsubscribeGroup( required numeric id, required string email )`
Convenience method for adding a single email address to an unsubscribe group. Delegates to `addEmailsToUnsubscribeGroup()`

#### `listEmailsByUnsubscribeGroup( required numeric id )`
Retrieve all suppressed email addresses belonging to the given group.

#### `deleteEmailFromUnsubscribeGroup( required numeric id, required string email )`
Remove a suppressed email address from the given suppression group.

#### `listAllSupressions()`
Retrieve a list of all suppressions.

#### `listUnsubscribeGroupsByEmail( required string email )`
Appears to slightly differ from the documentation. Returns all supressions groups, with an indication if the email address is supressed or not.

#### `searchUnsubscribeGroupForEmails( required numeric id, required array emails )`
Search a suppression group for multiple suppressions.

#### `searchUnsubscribeGroupForEmail( required numeric id, required string email )`
Convenience method for searching for a single email within an unsubscribe group. Delegates to `searchUnsubscribeGroupForEmails()`

---

### Suppressions - Unsubscribe Groups Reference
*View SendGrid Docs for [Suppressions - Unsubscribe Groups](https://sendgrid.com/docs/API_Reference/Web_API_v3/Suppression_Management/groups.html)*

#### `createUnsubscribeGroup( required string name, required string description, boolean isDefault )`
Create a new unsubscribe suppression group. The `name` and `description` arguments are both required. They can be seen by recipients on the unsubscribe landing page. SendGrid enforces the max length of these arguments by silently trimming their values to 30 and 100 characters, respectively.

#### `listUnsubscribeGroups()`
Retrieve a list of all suppression groups created by this user.

#### `getUnsubscribeGroup( required numeric id )`
Retrieve a single suppression group.

#### `updateUnsubscribeGroup( required numeric id, string name = '', string description = '', required boolean isDefault )`
Update an unsubscribe suppression group. The `name` and `description` arguments can be seen by recipients on the unsubscribe landing page. SendGrid enforces the max length of these arguments by silently trimming their values to 30 and 100 characters, respectively. For updates, the `isDefault` argument is required by this library, because if you don't supply it, SendGrid assumes false, which is confusing.

#### `deleteUnsubscribeGroup( required numeric id )`
Delete a suppression group.

---

### Cancel Scheduled Sends Reference
*View SendGrid Docs for [Cancel Scheduled Sends](https://sendgrid.com/docs/API_Reference/Web_API_v3/cancel_schedule_send.html)*

#### `generateBatchId()`
Generate a new batch ID. This batch ID can be associated with scheduled sends via the mail/send endpoint.

---

### Spam Reports API Reference
*View SendGrid Docs for [Spam Reports](https://sendgrid.com/docs/API_Reference/Web_API_v3/spam_reports.html)*

#### `listSpamReports( any start_time = 0, any end_time = 0, numeric limit = 0, numeric offset = 0 )`
Retrieve a list of spam reports that are currently on your spam reports list. The `start_time` and `end_time` arguments, if numeric, are assumed to be unix timestamps. Otherwise, they are presumed to be a valid date that will be converted to unix timestamps automatically.

#### `getSpamReport( required string email )`
Retrieve a specific spam report by email address.

---

### Validate Email
*View SendGrid Docs for [Validate Email](https://sendgrid.api-docs.io/v3.0/email-address-validation/validate-an-email)

#### `validateEmail( string email, string source = '' )`
Retrive a validation information about an email address. The source param is just an one word classifier for the validation call.

---

## Reference Manual for `helpers.mail`
This section documents every public method in the `helpers/mail.cfc` file. A few notes about structure, data, and usage:

- Unless indicated, all methods are chainable.
- Top level parameters are referred to as "global" or "message level", as opposed to personalized parameters. As the SendGrid docs state: "Individual fields within the personalizations array will override any other global, or “message level”, parameters that are defined outside of personalizations."
- Email address parameters can be passed in either as strings or structs.
  - When passed as a string, they can be in the format: Person \<name@email.com\>, in order to pass both name and email address.
  - When passed as a struct, the keys should be `email` and `name`, respectively. Only email is required.

#### `from( required any email )`

#### `replyTo( required any email )`

#### `subject( required string subject )`
Sets the global subject. This may be overridden by personalizations[x].subject.

#### `html( required string message )`
Convenience method for adding the text/html content

#### `plain( required string message )`
Convenience method for adding the text/plain content

#### `emailContent( required struct content, boolean doAppend = true )`
Method for setting any content mime-type. The default is that the new mime-type is appended to the Content array, but you can override this and have it prepended. This is used internally to ensure that `text/plain` precedes `text/html`, in accordance with the RFC specs, as enforced by SendGrid.

#### `plainFromHtml( string message = '' )`
Convenience method for setting both `text/html` and `text/plain` at the same time. You can either pass in the HTML content as the message argument, and both will be set from it (using an internal method to strip the HTML for the plain text version), or you can call the method without an argument, after having set the HTML, and that will be used.

#### `attachments( required array attachments )`
Sets the `attachments` property for the global message. If any attachments were previously set, this method overwrites them.

#### `addAttachment( required struct attachment )`
Appends a single attachment to the message. The attachment argument is struct with at minimum keys for `content` and `filename`. View the SendGrid docs for the full makeup and requirements of the object: https://sendgrid.api-docs.io/v3.0/mail-send

#### `attachFile( required string filePath, string fileName, string type, string disposition = 'attachment', string content_id )`
A convenience method for appending a single file attachment to the message. All that is required is the relative or absolute path to an on-disk file. Its properties are used if the additional arguments aren't provided.

#### `templateId( required string templateId )`
Sets the id of a template that you would like to use for the message

#### `section( required any section, any value )`
Appends a single section block to the global message's `sections` property. I'd recommend reading up on the somewhat [limited](https://sendgrid.com/docs/Classroom/Build/Add_Content/substitution_and_section_tags.html) [documentation](https://sendgrid.com/docs/API_Reference/SMTP_API/section_tags.html) SendGrid provides about sections and substitutions for more clarity on how they should be structured and used.

You can set a section by providing the section tag and replacement value separately, or by passing in a struct with a key/value pair; for example, `{ "-greeting-" : 'Welcome -first_name- -last_name-,' }`.

#### `sections( required struct sections )`
Sets the `sections` property for the global message. If any sections were previously set, this method overwrites them.

#### `header( required any header, any value )`
Appends a single header to the global message's `headers` property. This can be overridden by a personalized header.

You can set a header by providing the header and value separately, or by passing in a struct with a key/value pair; for example, `{ "X-my-application-name" : 'testing' }`.

#### `headers( required struct headers )`
Sets the `headers` property for the global message. Headers can be overridden by a personalized header. If any headers are set, this method overwrites them.

#### `categories( required any categories )`
Sets the category array for the global message. If categories are already set, this overwrites them. The argument can be passed in as an array or comma separated list. Lists will be converted to arrays

#### `addCategory( required string category )`
Appends a single category to the global message category array

#### `customArg( required any arg, any value )`
Appends a single custom argument on the global message's `custom_args` property. This can be overridden by a personalized custom argument.

You can set a custom argument by providing the argument's name and value separately, or by passing in a struct with a key/value pair; for example, `{ "Team": "Engineering" }`.

#### `customArgs( required struct args )`
Sets the `custom_args` property for the global message. Custom arguments can be overridden by a personalized custom argument. If any custom arguments are set, this overwrites them.

#### `sendAt( required date timeStamp )`
Sets the global `send_at` property, which specifies when you want the email delivered. This may be overridden by the personalizations[x].send_at.

#### `batchId( required string batchId )`
Sets the global `batch_id` property, which represents a group of emails that are associated with each other. The sending of emails in a batch can be cancelled or paused. Note that you must generate the batchID value via the API.

#### `mailSettings( required struct settings )`
Sets the `mail_settings` property for the global message. If any mail settings were previously set, this method overwrites them. While this makes it possible to pass in the fully constructed mail settings struct, the preferred method of setting mail settings is by using their dedicated methods.

#### `mailSetting( required any setting, any value )`
Generic method for defining individual mail settings. Using the dedicated methods for defining mail settings is usually preferable to invoking this directly.

You can define a setting by providing the setting key and its value separately, or by passing in a struct with a key/value pair; for example, `{ "sandbox_mode" : { "enable" : true } }`.

#### `bccSetting( required boolean enable, string email = '' )`
Sets the global `mail_settings.bcc` property, which allows you to have a blind carbon copy automatically sent to the specified email address for every email that is sent. Using the dedicated enable/disable bcc methods is usually preferable.

#### `enableBcc( required string email )`
Convenience method for enabling the `bcc` mail setting and setting the address

#### `disableBcc()`
Convenience method for disabling the `bcc` mail setting

#### `bypassListManagementSetting( required boolean enable )`
Sets the global `mail_settings.bypass_list_management` property, which allows you to bypass all unsubscribe groups and suppressions to ensure that the email is delivered to every single recipient. According to SendGrid, this should only be used in emergencies when it is absolutely necessary that every recipient receives your email. Using the dedicated enable/disable methods is usually preferable to invoking this directly

#### `enableBypassListManagement()`
Convenience method for disabling the `bypass_list_management` mail setting

#### `disableBypassListManagement()`
Convenience method for disabling the `bypass_list_management` mail setting

#### `footerSetting( required boolean enable, string text = '', string html = '' )`
Sets the global `mail_settings.footer` property, which provides the option for setting a default footer that you would like included on every email. Using the dedicated enable/disable methods is usually preferable.

#### `enableFooter( required string text, required string html )`
Convenience method for enabling the `footer` mail setting and setting the text/html

#### `disableFooter()`
Convenience method for disabling the `footer` mail setting

#### `sandboxModeSetting( required boolean enable )`
Sets the global `mail_settings.sandbox_mode` property, which allows allows you to send a test email to ensure that your request body is valid and formatted correctly. Sandbox mode is only used to validate your request. The email will never be delivered while this feature is enabled! Using the dedicated enable/disable methods is usually preferable to invoking this directly. You can [read more here](https://sendgrid.com/docs/Classroom/Send/v3_Mail_Send/sandbox_mode.html).

#### `enableSandboxMode()`
Convenience method for disabling the `sandbox_mode` mail setting

#### `disableSandboxMode()`
Convenience method for disabling the `sandbox_mode` mail setting

#### `spamCheckSetting( required boolean enable, numeric threshold = 0, string post_to_url = '' )`
Sets the global `mail_settings.spam_check` property, which allows you to test the content of your email for spam. Using the dedicated enable/disable methods is usually preferable.

#### `enableSpamCheck( required numeric threshold, required string post_to_url )`
Convenience method for enabling the `spam_check` mail setting and setting the threshold and post_to_url

#### `disableSpamCheck()`
Convenience method for disabling the `spam_check` mail setting

#### `to( required any email )`
Adds a **new** personalization envelope, with only the specified email address. The personalization can then be further customized with later commands. I found personalizations a little tricky. You can [read more here](https://sendgrid.com/docs/Classroom/Send/v3_Mail_Send/personalizations.html).

#### `addTo( required any email )`
Adds an additional 'to' recipient to the **current** personalization envelope

#### `addCC( required any email )`
Adds an additional 'cc' recipient to the **current** personalization envelope. You need to add a 'to' recipient before using this.

#### `addBCC( required any email )`
Adds an additional 'bcc' recipient to the **current** personalization envelope. You need to add a 'to' recipient before using this.

#### `withSubject ( required string subject )`
Sets the subject for the current personalization envelope. This overrides the global email subject for these recipients. A basic personalization envelope (with a 'to' recipient) needs to be in place before this can be added.

#### `withHeader ( any header, any value )`
Functions like `header()`, except it adds the header to the **current** personalization envelope.

#### `withHeaders( required struct headers )`
Functions like `headers()`, except it sets the `headers` property for the **current** personalization envelope. If any personalized headers are set, this method overwrites them.

#### `withSubstitution ( any substitution, any value )`
Appends a substitution ( "substitution_tag" : "value to substitute" ) to the **current** personalization envelope. You can add a substitution by providing the tag and value to substitute, or by passing in a struct.

#### `withSubstitutions( required struct substitutions )`
Sets the `substitutions` property for the **current** personalization envelope. If any substitutions are set, this method overwrites them.

#### `withCustomArg( required any arg, any value )`
Functions like `customArg()`, except it adds the custom argument to the **current** personalization envelope.

#### `withCustomArgs( required struct args )`
Functions like `customArgs()`, except it sets the `custom_args` property for the **current** personalization envelope. If any personalized custom arguments are set, this method overwrites them.

#### `withSendAt( required date timeStamp )`
Functions like `sendAt()`, except it sets the desired send time for the **current** personalization envelope.

#### `build()`
The function that puts it all together and builds the body for `/mail/send`


## Reference Manual for `helpers.campaign`
This section documents every public method in the `helpers/campaign.cfc` file. A few notes about structure, data, and usage:

- Unless indicated, all methods are chainable.

#### `title( required string title )`
Sets the display title of your campaign. This will be viewable by you in the Marketing Campaigns UI. This is the only required field for creating a campaign

#### `subject( required string subject )`
Sets the subject of your campaign that your recipients will see.

#### `sender( required numeric id )`
Sets who the email is "from", using the ID of the "sender" identity that you have created.

#### `fromSender( required numeric id )`
Included in order to provide a more fluent interface; delegates to `sender()`

#### `useLists( required array lists )`
Sets the IDs of the lists you are sending this campaign to. Note that you can have both segment IDs and list IDs. If any list Ids were previously set, this method overwrites them. The `lists` arguments can be passed in as an array or comma separated list. Lists will be converted to arrays.

#### `useList( required numeric id )`
Appends a single list Id to the array of List Ids that this campaign is being sent to.

#### `useSegments( required any segments )`
Sets the segment IDs that you are sending this list to. Note that you can have both segment IDs and list IDs. If any segment Ids were previously set, this method overwrites them. The `segments` argument can be passed in as an array or comma separated list. Lists will be converted to arrays.

#### `useSegment( required numeric id )`
Appends a single segment Id to the array of Segment Ids that this campaign is being sent to.

#### `categories( required any categories )`
Set an array of categories you would like associated to this campaign. If categories are already set, this overwrites them. The `categories` argument can be passed in as an array or comma separated list. Lists will be converted to arrays.

#### `addCategory( required string category )`
Appends a single category to campaigns array of categories.

#### `suppressionGroupId( required numeric id )`
Assigns the suppression group that this marketing email belongs to, allowing recipients to opt-out of emails of this type. Note that you cannot provide both a suppression group Id and a custom unsubscribe url. The two are mutually exclusive.

#### `useSuppressionGroup( required numeric id )`
Included in order to provide a more fluent interface; delegates to `suppressionGroupId()`

#### `customUnsubscribeUrl( required string uri )`
This is the url of the custom unsubscribe page that you provide for customers to unsubscribe from mailings. Using this takes the place of having SendGrid manage your suppression groups.

#### `useCustomUnsubscribeUrl( required string uri )`
Included in order to provide a more fluent interface; delegates to `customUnsubscribeUrl()`

#### `ipPool( required string name )`
The pool of IPs that you would like to send this email from. Note that your SendGrid plan must include dedicated IPs in order to use this.

#### `fromIpPool( required string name )`
Included in order to provide a more fluent interface; delegates to `ipPool()`

#### `html( required string message )`
Convenience method for adding the text/html content

#### `htmlContent( required string message )`
Redundant, but included for consistency in naming the methods for setting attributes. Delegates to `html()`

#### `plain( required string message )`
Convenience method for adding the text/plain content

#### `plainContent( required string message )`
Redundant, but included for consistency in naming the methods for setting attributes. Delegates to `plain()`

#### `plainFromHtml( string message = '' )`
Convenience method for setting both html and plain at the same time. You can either pass in the HTML content, and both will be set from it (using a method to strip the HTML for the plain text version), or you can call the method without an argument, after having set the HTML, and that will be used.

#### `useDesignEditor()`
The editor used in the UI. Because it defaults to `code`, it really only needs to be toggled to `design`

#### `useCodeEditor()`
The editor used in the UI. It defaults to `code`, so this shouldn't be needed, but it's provided for consistency.

#### `build()`
The function that puts it all together and builds the body for campaign related API operations.

## Reference Manual for `helpers.sender`
This section documents every public method in the `helpers/sender.cfc` file. A few notes about structure, data, and usage:

- Unless indicated, all methods are chainable.
- Email address parameters can be passed in either as strings or structs.
  - When passed as a string, they can be in the format: Person \<name@email.com\>, in order to pass both name and email address.
  - When passed as a struct, the keys should be `email` and `name`, respectively.

#### `nickname( required string nickname )`
Sets the nickname for the sender identity. Not used for sending, but required.

#### `from( required any email )`
Set where the email will appear to originate from for your recipients. Note that, despite what the documentation says, both email address and name need to be provided. If a string is passed in and the name is not provided, the email address will be used as the name as well.

#### `replyTo( required any email )`
Set where your recipients will reply to. If a string is passed in and the name is not provided, the email address will be used as the name as well.

#### `address( required string address )`
Required. Sets the physical address of the sender identity.

#### `address2( required string address )`
Provides additional sender identity address information.

#### `city( required string city )`
Required.

#### `state( required string state )`

#### `zip( required string zip )`

#### `country( required string country )`
Required.

#### `build()`
The function that puts it all together and builds the body for sender related API operations

# Questions
For questions that aren't about bugs, feel free to hit me up on the [CFML Slack Channel](http://cfml-slack.herokuapp.com); I'm @mjclemente. You'll likely get a much faster response than creating an issue here.

# Contributing
:+1::tada: First off, thanks for taking the time to contribute! :tada::+1:

Before putting the work into creating a PR, I'd appreciate it if you opened an issue. That way we can discuss the best way to implement changes/features, before work is done.

Changes should be submitted as Pull Requests on the `develop` branch.