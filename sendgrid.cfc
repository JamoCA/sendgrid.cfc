/**
* sendgrid.cfc
* Copyright 2017-2020 Matthew Clemente, John Berquist
* Licensed under MIT (https://github.com/mjclemente/sendgrid.cfc/blob/master/LICENSE)
*/
component output="false" displayname="SendGrid.cfc"  {

  variables._sendgridcfc_version = '0.9.2';

  public any function init(
    string apiKey = '',
    string emailValidationApiKey = '',
    string baseUrl = "https://api.sendgrid.com/v3",
    boolean forceTestMode = false,
    numeric httpTimeout = 50,
    boolean includeRaw = false ) {

    structAppend( variables, arguments );

    //map sensitive args to env variables or java system props
    var secrets = {
      'apiKey': 'SENDGRID_API_KEY',
      'emailValidationApiKey': 'SENDGRID_EMAIL_VALIDATION_API_KEY'
    };
    var system = createObject( 'java', 'java.lang.System' );

    for ( var key in secrets ) {
      //arguments are top priority
      if ( variables[ key ].len() ) continue;

      //check environment variables
      var envValue = system.getenv( secrets[ key ] );
      if ( !isNull( envValue ) && envValue.len() ) {
        variables[ key ] = envValue;
        continue;
      }

      //check java system properties
      var propValue = system.getProperty( secrets[ key ] );
      if ( !isNull( propValue ) && propValue.len() ) {
        variables[ key ] = propValue;
      }
    }

    variables.utcBaseDate = dateAdd( "l", createDate( 1970,1,1 ).getTime() * -1, createDate( 1970,1,1 ) );

    return this;
  }

  /**
  * Mail Send
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/Mail/index.html
  */

  /**
  * @hint Send email, using SendGrid's REST API
  * @mail must be an instance of the `helpers.mail` component
  */
  public struct function sendMail( required component mail ) {
    if ( variables.forceTestMode ) mail.enableSandboxMode();

    return apiCall( 'POST', '/mail/send', {}, mail.build() );
  }

  /**
  * Blocks API
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/blocks.html
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/blocks-api/retrieve-all-blocks
  * @hint Retrieve a list of all email addresses that are currently on your blocks list.
  * @start_time Start of the time range when the blocked email was created. If numeric, it's assumed to be a unix timestamp. Otherwise, it's presumed to be a valid date that will be converted to a unix timestamp automatically
  * @end_time End of the time range when the blocked email was created. If numeric, it's assumed to be a unix timestamp. Otherwise, it's presumed to be a valid date that will be converted to a unix timestamp automatically
  */
  public struct function listBlocks( any start_time = 0, any end_time = 0, numeric limit = 0, numeric offset = 0 ) {
    var params = {};
    if ( !isValid( 'integer', start_time ) )
      params[ 'start_time' ] = returnUnixTimestamp( start_time );
    else if ( start_time )
      params[ 'start_time' ] = start_time;

    if ( !isValid( 'integer', end_time ) )
      params[ 'end_time' ] = returnUnixTimestamp( end_time );
    else if ( end_time )
      params[ 'end_time' ] = end_time;

    if ( limit ) params[ 'limit' ] = limit;
    if ( offset ) params[ 'offset' ] = offset;

    return apiCall( 'GET', "/suppression/blocks", params );
  }

  /**
  * @todo Look into workaround, as CF doesn't send the request body for DELETE
  * https://sendgrid.api-docs.io/v3.0/blocks-api/delete-blocks
  * @hint Delete email addresses on your blocks list
  */
  // public struct function deleteBlocks( boolean delete_all = false, array emails = [] ) {
  //   var body = {
  //     'delete_all' : delete_all,
  //     'emails' : emails
  //   };
  //   return apiCall( 'DELETE', "/suppression/blocks", {}, body );
  // }

  /**
  * https://sendgrid.api-docs.io/v3.0/blocks-api/retrieve-a-specific-block
  * @hint Retrieve a specific email address from your blocks list.
  */
  public struct function getBlock( required string email ) {
    return apiCall( 'GET', "/suppression/blocks/#email#" );
  }

  /**
  * Bounces API
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/bounces.html
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/bounces-api/retrieve-all-bounces
  * @hint Retrieve a list of bounces that are currently on your bounces list.
  * @start_time Start of the time range when the bounce was created. If numeric, it's assumed to be a unix timestamp. Otherwise, it's presumed to be a valid date that will be converted to a unix timestamp automatically
  * @end_time End of the time range when the bounce was created. If numeric, it's assumed to be a unix timestamp. Otherwise, it's presumed to be a valid date that will be converted to a unix timestamp automatically
  */
  public struct function listBounces( any start_time = 0, any end_time = 0, numeric limit = 0, numeric offset = 0 ) {
    var params = {};
    if ( !isValid( 'integer', start_time ) )
      params[ 'start_time' ] = returnUnixTimestamp( start_time );
    else if ( start_time )
      params[ 'start_time' ] = start_time;

    if ( !isValid( 'integer', end_time ) )
      params[ 'end_time' ] = returnUnixTimestamp( end_time );
    else if ( end_time )
      params[ 'end_time' ] = end_time;

    if ( limit ) params[ 'limit' ] = limit;
    if ( offset ) params[ 'offset' ] = offset;

    return apiCall( 'GET', "/suppression/bounces", params );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/bounces-api/retrieve-a-bounce
  * @hint Retrieve specific bounce information for a given email address.
  */
  public struct function getBounce( required string email ) {
    return apiCall( 'GET', "/suppression/bounces/#email#" );
  }

  /**
  * Campaigns API
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/campaigns.html
  */

  /**
  * @hint Create a marketing campaign.
  * @campaign this should be an instance of the `helpers.campaign` component. However, if you want to create and pass in the struct or json yourself, you can.
  */
  public struct function createCampaign( required any campaign ) {
    var body = {};
    if ( isValid( 'component', campaign ) )
      body = campaign.build();
    else
      body = campaign;
    return apiCall( 'POST', '/campaigns', {}, body );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/campaigns-api/retrieve-all-campaigns
  * @hint Retrieve a list of all of your campaigns.
  */
  public struct function listCampaigns() {
    return apiCall( 'GET', "/campaigns" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/campaigns-api/retrieve-a-single-campaign
  * @hint Retrieve a single campaign by ID.
  */
  public struct function getCampaign( required numeric id ) {
    return apiCall( 'GET', "/campaigns/#id#" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/campaigns-api/delete-a-campaign
  * @hint Delete a single campaign by ID.
  */
  public struct function deleteCampaign( required numeric id ) {
    return apiCall( 'DELETE', "/campaigns/#id#" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/campaigns-api/update-a-campaign
  * @hint Update a campaign by ID.
  * @campaign this should be an instance of the `helpers.campaign` component. However, if you want to create and pass in the struct or json yourself, you can.
  */
  public struct function updateCampaign( required numeric id, required any campaign ) {
    var body = {};
    if ( isValid( 'component', campaign ) )
      body = campaign.build();
    else
      body = campaign;
    return apiCall( 'PATCH', '/campaigns/#id#', {}, body );
  }


  /**
  * Contacts API - Recipients
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html#-Recipients
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/add-recipients
  * @hint Add Marketing Campaigns recipients. Note that it also appears to update existing records, so it basically functions like a PATCH.
  * @recipients an array of objects, with at minimum, and 'email' key/value
  */
  public struct function addRecipients( required array recipients ) {
    return upsertRecipients( 'POST', recipients );
  }

  /**
  * @hint Convenience method for adding a single recipient at a time.
  * @recipient Facilitates two means of adding a recipient. You can pass in a struct with key/value pairs providing all relevant recipient information. Alternatively, you can use this to simply pass in the recipient's email address, which is all that is required.
  * @customFields keys correspond to the custom field names, along with their assigned values
  */
  public struct function addRecipient( required any recipient, string first_name = '', string last_name = '', struct customFields = {} ) {
    return upsertRecipient( 'POST', recipient, first_name, last_name, customFields );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/update-recipient
  * @hint Update one or more Marketing Campaign recipients. Note that it will also add non-existing records.
  * @recipients an array of objects, with at minimum, and 'email' key/value
  */
  public struct function updateRecipients( required array recipients ) {
    return upsertRecipients( 'PATCH', recipients );
  }

  /**
  * @hint convenience method for updating a single recipient at a time.
  * @recipient Facilitates two means of updating a recipient. You can pass in a struct with key/value pairs providing all relevant recipient information. Alternatively, you can use this to simply pass in the recipient's email address, which is all that is required.
  * @customFields keys correspond to the custom field names, along with their assigned values
  */
  public struct function updateRecipient( required any recipient, string first_name = '', string last_name = '', struct customFields = {} ) {
    return upsertRecipient( 'PATCH', recipient, first_name, last_name, customFields );
  }

  /**
  * @hint shared private method for handling insert/update requests for individual recipients. Deletegates to `upsertRecipients()`
  */
  private struct function upsertRecipient( required string method, required any recipient, string first_name = '', string last_name = '', struct customFields = {} ) {
    var recipients = [];
    var contact = {};

    if ( isStruct( recipient ) )
      contact.append( recipient );
    else
      contact[ 'email' ] = recipient;

    if ( first_name.len() )
      contact[ 'first_name' ] = first_name;

    if ( last_name.len() )
      contact[ 'last_name' ] = last_name;

    if ( !customFields.isEmpty() )
      contact.append( customFields, false );

    recipients.append( contact );

    return upsertRecipients( method, recipients );
  }

  /**
  * @hint shared private method for inserting/updating recipients
  */
  private struct function upsertRecipients( required string method, required array recipients ) {
    return apiCall( method, '/contactdb/recipients', {}, recipients );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/get-recipient-upload-status
  * @hint Check the upload status of a Marketing Campaigns recipient.
  */
  public struct function getRecipientUploadStatus() {
    return apiCall( 'GET', "/contactdb/status" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/delete-a-recipient
  * @hint Delete a single recipient with the given ID from your contact database.
  * @id the recipient ID or email address (which will be converted to the recipient ID).
  */
  public struct function deleteRecipient( required string id ) {
    return apiCall( 'DELETE', "/contactdb/recipients/#returnRecipientId( id )#" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/delete-recipient
  * @hint Deletes one or more recipients. This is an incomplete implementation of the SendGrid API. Technically, this should send a DELETE request to `/contactdb/recipients`, with an array of IDs as the body. But ColdFusion doesn't currently include the request body in DELETE calls. So we loop the recipients through the individual delete method.
  * @recipients An array of the recipient IDs you want to delete. You can also provide their email addresses, and they will be converted to recipient IDs
  */
  public struct function deleteRecipients( required array recipients ) {
    var result = {};
    for ( var recipientId in recipients ) {
      result = deleteRecipient( recipientId );
    }
    return result;
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/retrieve-recipients
  * @hint Retrieve all of your Marketing Campaign recipients.
  * @page Page index of first recipients to return (must be a positive integer)
  * @pageSize Number of recipients to return at a time (must be a positive integer between 1 and 1000)
  */
  public struct function listRecipients( numeric page = 0, numeric pageSize = 0 ) {
    var params = {};
    if ( page )
      params[ 'page' ] = page;
    if ( pageSize )
      params[ 'page_size' ] = pageSize;

    return apiCall( 'GET', "/contactdb/recipients", params );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/retrieve-a-single-recipient
  * @hint Retrieve a single recipient by ID from your contact database.
  * @id the recipient ID or email address (which will be converted to the recipient ID).
  */
  public struct function getRecipient( required string id ) {
    return apiCall( 'GET', "/contactdb/recipients/#returnRecipientId( id )#" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/retrieve-the-lists-that-a-recipient-is-on
  * @hint Retrieve the lists that a given recipient belongs to.
  * @id the recipient ID or email address (which will be converted to the recipient ID).
  */
  public struct function listListsByRecipient( required string id ) {
    return apiCall( 'GET', "/contactdb/recipients/#returnRecipientId( id )#/lists" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/retrieve-the-count-of-billable-recipients
  * @hint Retrieve the number of Marketing Campaigns recipients that you will be billed for.
  */
  public struct function getBillableRecipientCount() {
    return apiCall( 'GET', "/contactdb/recipients/billable_count" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/retrieve-a-count-of-recipients
  * @hint Retrieve the total number of Marketing Campaigns recipients.
  */
  public struct function getRecipientCount() {
    return apiCall( 'GET', "/contactdb/recipients/count" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/retrieve-recipients-matching-search-criteria
  * @hint Perform a search on all of your Marketing Campaigns recipients.
  * @fieldName the name of a custom field or reserved field
  * @search the value to search for within the specified field. Date fields must be unix timestamps. Currently, searches that are formatted as a U.S. date in the format mm/dd/yyyy (1-2 digit days and months, 1-4 digit years) are converted automatically.
  */
  public struct function searchRecipients( required string fieldName, any search = '' ) {
    var params = {
      "#fieldName#" : !isValid( 'USdate', search ) ? search : returnUnixTimestamp( search )
    };
    return apiCall( 'GET', "/contactdb/recipients/search", params );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-recipients/Create_Search%20with%20conditions
  * POST /contactdb/recipients/search
  * Note that this endpoint exists, providing more robust, segmented search. However, I don't see support for it in any of the official libraries, so I'm not going to bother to put it together here, unless there's a need for it.
  */

  /**
  * @hint Helper method, which allows for passing in the recipient id or email address and returns the id, which is needed. The recipient Id is a URL-safe base64 encoding of the recipient's lower cased email address
  */
  private string function returnRecipientId( required string id ) {
    return isValid( 'email', id ) ? toBase64( id ) : id;
  }

  /**
  * Contacts API - Custom Fields
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html#-Custom-Fields
  */

  /**
  * @hint Create a custom field.
  * @type allowed values are 'text', 'date', and 'number'
  */
  public struct function createCustomField( required string name, required string type ) {
    var body = {
      'name' : name,
      'type' : type
    };
    return apiCall( 'POST', '/contactdb/custom_fields', {}, body );
  }

  /**
  * @hint Retrieve all custom fields.
  */
  public struct function listCustomFields() {
    return apiCall( 'GET', "/contactdb/custom_fields" );
  }

  /**
  * @hint Retrieve a custom field by ID.
  */
  public struct function getCustomField( required numeric id ) {
    return apiCall( 'GET', "/contactdb/custom_fields/#id#" );
  }

  /**
  * @hint Delete a custom field by ID.
  */
  public struct function deleteCustomField( required numeric id ) {
    return apiCall( 'DELETE', "/contactdb/custom_fields/#id#" );
  }

  /**
  * @hint List all fields that are reserved and can't be used for custom field names.
  */
  public struct function listReservedFields() {
    return apiCall( 'GET', "/contactdb/reserved_fields" );
  }


  /**
  * Contacts API - Lists
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html#-Lists
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-lists/create-a-list
  * @hint Create a list for your recipients.
  */
  public struct function createList( required string name ) {
    var body = {
      'name' : name
    };
    return apiCall( 'POST', '/contactdb/lists', {}, body );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-lists/retrieve-all-lists
  * @hint Retrieve all of your recipient lists. If you don't have any lists, an empty array will be returned.
  */
  public struct function listLists() {
    return apiCall( 'GET', '/contactdb/lists' );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-lists/delete-multiple-lists
  * @hint Delete multiple recipient lists. This is an incomplete implementation of the SendGrid API. Technically, this should send a DELETE request to `/contactdb/lists`, with an array of IDs as the body. But ColdFusion doesn't currently include the request body in DELETE calls. So we loop the lists through the individual delete method.
  * @recipients An array of the list IDs you want to delete
  */
  public struct function deleteLists( required array lists ) {
    var result = {};
    for ( var listId in lists ) {
      result = deleteList( listId );
    }
    return result;
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-lists/delete-a-list
  * @hint Delete a single list with the given ID from your contact database.
  */
  public struct function deleteList( required numeric id ) {
    return apiCall( 'DELETE', "/contactdb/lists/#id#" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-lists/retrieve-a-single-list
  * @hint Retrieve a single recipient list by ID.
  */
  public struct function getList( required numeric id ) {
    return apiCall( 'GET', "/contactdb/lists/#id#" );
  }

  /**
  * @hint Update the name of one of your recipient lists.
  */
  public struct function updateList( required numeric id, required string name ) {
    var body = {
      'name' : name
    };
    return apiCall( 'PATCH', "/contactdb/lists/#id#", {}, body );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-lists/retrieve-all-recipients-on-a-list
  * @hint Retrieve all recipients on the list with the given ID.
  * @page Page index of first recipient to return (must be a positive integer)
  * @pageSize Number of recipients to return at a time (must be a positive integer between 1 and 1000)
  */
  public struct function listRecipientsByList( required numeric id, numeric page = 0, numeric pageSize = 0 ) {
    var params = {};

    if ( page )
      params[ 'page' ] = page;
    if ( pageSize )
      params[ 'page_size' ] = pageSize;

    return apiCall( 'GET', "/contactdb/lists/#id#/recipients", params );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-lists/add-a-single-recipient-to-a-list
  * @hint Add a single recipient to a list.
  * @recipientId The recipient ID or email address (which will be converted to the recipient ID)
  */
  public struct function addRecipientToList( required numeric listId, required string recipientId ) {
    return apiCall( 'POST', '/contactdb/lists/#listId#/recipients/#returnRecipientId( recipientId )#' );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-lists/delete-a-single-recipient-from-a-single-list
  * @hint Delete a single recipient from a list.
  * @recipientId The recipient ID or email address (which will be converted to the recipient ID)
  */
  public struct function deleteRecipientFromList( required numeric listId, required string recipientId ) {
    return apiCall( 'DELETE', '/contactdb/lists/#listId#/recipients/#returnRecipientId( recipientId )#' );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-lists/add-multiple-recipients-to-a-list
  * @hint Add multiple recipients to a list.
  * @recipients an array of recipient IDs or email addresses
  */
  public struct function addRecipientsToList( required numeric listId, required array recipients ) {
    var recipientIds = recipients;

    if ( recipients.len() && isValid( 'email', recipients[1] ) ) {
      recipientIds = recipients.map(
        function( item, index ) {
          return returnRecipientId( item );
        }
      );
    }

    return apiCall( 'POST', '/contactdb/lists/#listId#/recipients', {}, recipientIds );
  }

  /**
  * Contacts API - Segments
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html#-Segments
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-segments/create-a-segment
  * @hint Create a segment using search conditions.
  * @conditions an array of structs making up the search conditions that define this segment. Read SendGrid documentation for specifics on how to segment contacts.
  * @listId The list id from which to make this segment. Not including this ID will mean your segment is created from the main contactdb rather than a list.
  */
  public struct function createSegment( required string name, required array conditions, numeric listId = 0 ) {
    var body = {
      'name' : name,
      'conditions' : conditions
    };
    if ( listID )
      body[ 'list_id' ] = listId;
    return apiCall( 'POST', '/contactdb/segments', {}, body );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-segments/retrieve-all-segments
  * @hint Retrieve all of your segments.
  */
  public struct function listSegments() {
    return apiCall( 'GET', '/contactdb/segments' );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-segments/retrieve-a-segment
  * @hint Retrieve a single segment with the given ID.
  */
  public struct function getSegment( required numeric id ) {
    return apiCall( 'GET', "/contactdb/segments/#id#" );
  }

  /**
  * @hint Update a segment. Functions similarly to `createSegment()`, but you only need to include the parameters you are updating.
  * @listId The list id from which to make this segment. Note that this can be used to change the list for this segment, but once a list has been set, the segment cannot be returned to the main contactdb
  */
  public struct function updateSegment( required numeric id, string name = '', array conditions = [], numeric listId = 0 ) {
    var body = {};
    if ( name.len() )
      body[ 'name' ] = name;
    if ( conditions.len() )
      body[ 'conditions' ] = conditions;
    if ( listID )
      body[ 'list_id' ] = listId;
    return apiCall( 'PATCH', "/contactdb/segments/#id#", {}, body );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-segments/delete-a-segment
  * @hint Delete a segment from your recipients database.
  */
  public struct function deleteSegment( required numeric id ) {
    return apiCall( 'DELETE', "/contactdb/segments/#id#" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/contacts-api-segments/retrieve-recipients-on-a-segment
  * @hint Retrieve all of the recipients in a segment with the given ID.
  */
  public struct function listRecipientsBySegment( required numeric id ) {
    return apiCall( 'GET', "/contactdb/segments/#id#/recipients" );
  }

  /**
  * Invalid Emails API
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/invalid_emails.html
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/invalid-emails-api/retrieve-all-invalid-emails
  * @hint Retrieve a list of invalid emails that are currently on your invalid emails list.
  * @start_time Start of the time range when the invalid email was created. If numeric, it's assumed to be a unix timestamp. Otherwise, it's presumed to be a valid date that will be converted to a unix timestamp automatically
  * @end_time End of the time range when the invalid email was created. If numeric, it's assumed to be a unix timestamp. Otherwise, it's presumed to be a valid date that will be converted to a unix timestamp automatically
  */
  public struct function listInvalidEmails( any start_time = 0, any end_time = 0, numeric limit = 0, numeric offset = 0 ) {
    var params = {};
    if ( !isValid( 'integer', start_time ) )
      params[ 'start_time' ] = returnUnixTimestamp( start_time );
    else if ( start_time )
      params[ 'start_time' ] = start_time;

    if ( !isValid( 'integer', end_time ) )
      params[ 'end_time' ] = returnUnixTimestamp( end_time );
    else if ( end_time )
      params[ 'end_time' ] = end_time;

    if ( limit ) params[ 'limit' ] = limit;
    if ( offset ) params[ 'offset' ] = offset;

    return apiCall( 'GET', "/suppression/invalid_emails", params );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/invalid-emails-api/retrieve-a-specific-invalid-email
  * @hint Retrieve information about a specific invalid email address.
  */
  public struct function getInvalidEmail( required string email ) {
    return apiCall( 'GET', "/suppression/invalid_emails/#email#" );
  }

  /**
  * Sender Identities API
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/sender_identities.html
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/sender-identities-api/create-a-sender-identity
  * @hint Create a new sender identity.
  * @sender this should be an instance of the `helpers.sender` component. However, if you want to create and pass in the struct or json yourself, you can.
  */
  public struct function createSender( required any sender ) {
    var body = {};
    if ( isValid( 'component', sender ) )
      body = sender.build();
    else
      body = sender;
    return apiCall( 'POST', '/senders', {}, body );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/sender-identities-api/get-all-sender-identities
  * @hint Retrieve a list of all sender identities that have been created for your account.
  */
  public struct function listSenders() {
    return apiCall( 'GET', '/senders' );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/sender-identities-api/update-a-sender-identity
  * @hint Update a sender identity by ID.
  * @sender this should be an instance of the `helpers.sender` component. However, if you want to create and pass in the struct or json yourself, you can.
  */
  public struct function updateSender( required numeric id, required any sender ) {
    var body = {};
    if ( isValid( 'component', sender ) )
      body = sender.build();
    else
      body = sender;
    return apiCall( 'PATCH', '/senders/#id#', {}, body );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/sender-identities-api/delete-a-sender-identity
  * @hint Delete a single sender identity by ID.
  */
  public struct function deleteSender( required numeric id ) {
    return apiCall( 'DELETE', "/senders/#id#" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/sender-identities-api/resend-sender-identity-verification
  * @hint Resend a sender identity verification email.
  */
  public struct function resendSenderVerification( required numeric id ) {
    return apiCall( 'POST', "/senders/#id#/resend_verification" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/sender-identities-api/view-a-sender-identity
  * @hint Retrieve a single sender identity by ID.
  */
  public struct function getSender( required numeric id ) {
    return apiCall( 'GET', "/senders/#id#" );
  }

  /**
  * Cancel Scheduled Sends
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/cancel_schedule_send.html
  */


  /**
  * https://sendgrid.api-docs.io/v3.0/cancel-scheduled-sends/create-a-batch-id
  * @hint Generate a new batch ID. This batch ID can be associated with scheduled sends via the mail/send endpoint.
  */
  public struct function generateBatchId() {
    return apiCall( 'POST', "/mail/batch" );
  }

  /**
  * Spam Reports API
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/spam_reports.html
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/spam-reports-api/retrieve-all-spam-reports
  * @hint Retrieve a list of spam reports that are currently on your spam reports list.
  * @start_time Start of the time range when the spam reports was created. If numeric, it's assumed to be a unix timestamp. Otherwise, it's presumed to be a valid date that will be converted to a unix timestamp automatically
  * @end_time End of the time range when the spam reports was created. If numeric, it's assumed to be a unix timestamp. Otherwise, it's presumed to be a valid date that will be converted to a unix timestamp automatically
  */
  public struct function listSpamReports( any start_time = 0, any end_time = 0, numeric limit = 0, numeric offset = 0 ) {
    var params = {};
    if ( !isValid( 'integer', start_time ) )
      params[ 'start_time' ] = returnUnixTimestamp( start_time );
    else if ( start_time )
      params[ 'start_time' ] = start_time;

    if ( !isValid( 'integer', end_time ) )
      params[ 'end_time' ] = returnUnixTimestamp( end_time );
    else if ( end_time )
      params[ 'end_time' ] = end_time;

    if ( limit ) params[ 'limit' ] = limit;
    if ( offset ) params[ 'offset' ] = offset;

    return apiCall( 'GET', "/suppression/spam_reports", params );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/spam-reports-api/retrieve-a-specific-spam-report
  * @hint Retrieve a specific spam report by email address
  */
  public struct function getSpamReport( required string email ) {
    return apiCall( 'GET', "/suppression/spam_reports/#email#" );
  }

  /**
  * Suppressions - Suppressions
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/Suppression_Management/suppressions.html
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-suppressions/add-suppressions-to-a-suppression-group
  * @hint Add email addresses to an unsubscribe group. If you attempt to add suppressions to a group that has been deleted or does not exist, the suppressions will be added to the global suppressions list.
  * @emails an array of email addresses
  */
  public struct function addEmailsToUnsubscribeGroup( required numeric id, required array emails ) {
    var recipientEmails = {
      'recipient_emails' : emails
    };
    return apiCall( 'POST', '/asm/groups/#id#/suppressions', {}, recipientEmails );
  }

  /**
  * @hint Convenience method for adding a single email address to an unsubscribe group. Delegates to `addEmailsToUnsubscribeGroup()`
  */
  public struct function addEmailToUnsubscribeGroup( required numeric id, required string email ) {
    return addEmailsToUnsubscribeGroup( id, [ email ] );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-suppressions/retrieve-all-suppressions-for-a-suppression-group
  * @hint Retrieve all suppressed email addresses belonging to the given group.
  */
  public struct function listEmailsByUnsubscribeGroup( required numeric id ) {
    return apiCall( 'GET', "/asm/groups/#id#/suppressions" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-suppressions/delete-a-suppression-from-a-suppression-group
  * @hint Remove a suppressed email address from the given suppression group.
  */
  public struct function deleteEmailFromUnsubscribeGroup( required numeric id, required string email ) {
    return apiCall( 'DELETE', '/asm/groups/#id#/suppressions/#email#' );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-suppressions/retrieve-all-suppressions
  * @hint Retrieve a list of all suppressions.
  */
  public struct function listAllSupressions() {
    return apiCall( 'GET', "/asm/suppressions" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-suppressions/retrieve-all-suppression-groups-for-an-email-address
  * @hint Appears to slightly differ from the documentation. Returns all supressions groups, with an indication if the email address is supressed or not.
  */
  public struct function listUnsubscribeGroupsByEmail( required string email ) {
    return apiCall( 'GET', "/asm/suppressions/#email#" );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-suppressions/search-for-suppressions-within-a-group
  * @hint Search a suppression group for multiple suppressions.
  */
  public struct function searchUnsubscribeGroupForEmails( required numeric id, required array emails ) {
    var recipientEmails = {
      'recipient_emails' : emails
    };
    return apiCall( 'POST', "/asm/groups/#id#/suppressions/search", {}, recipientEmails );
  }

  /**
  * @hint Convenience method for searching for a single email within an unsubscribe group. Delegates to `searchUnsubscribeGroupForEmails()`
  */
  public struct function searchUnsubscribeGroupForEmail( required numeric id, required string email ) {
    return searchUnsubscribeGroupForEmails( id, [ email ] );
  }

  /**
  * Suppressions - Unsubscribe Groups
  * https://sendgrid.com/docs/API_Reference/Web_API_v3/Suppression_Management/groups.html
  */

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-unsubscribe-groups/create-a-new-suppression-group
  * @hint Create a new unsubscribe suppression group.
  * @name Can be seen by recipients on the unsubscribe landing page. SendGrid enforces the max length (30) by silently trimming excess characters.
  * @description Can be seen by recipients on the unsubscribe landing page. SendGrid enforces the max length (100) by silently trimming excess characters.
  */
  public struct function createUnsubscribeGroup( required string name, required string description, boolean isDefault ) {
    var body = {
      'name' : name,
      'description' : description
    };
    if ( arguments.keyExists( isDefault ) )
      body[ 'is_default' ] = isDefault;

    return apiCall( 'POST', '/asm/groups', {}, body );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-unsubscribe-groups/retrieve-all-suppression-groups-associated-with-the-user
  * @hint Retrieve a list of all suppression groups created by this user.
  */
  public struct function listUnsubscribeGroups() {
    return apiCall( 'GET', '/asm/groups' );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-unsubscribe-groups/get-information-on-a-single-suppression-group
  * @hint Retrieve a single suppression group.
  */
  public struct function getUnsubscribeGroup( required numeric id ) {
    return apiCall( 'GET', '/asm/groups/#id#' );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-unsubscribe-groups/update-a-suppression-group
  * @hint Update an unsubscribe suppression group.
  * @name Can be seen by recipients on the unsubscribe landing page. SendGrid enforces the max length (30) by silently trimming excess characters.
  * @description Can be seen by recipients on the unsubscribe landing page. SendGrid enforces the max length (100) by silently trimming excess characters.
  * @isDefault Required by this library, because if you don't supply it, SendGrid assumes false, which is confusing.
  */
  public struct function updateUnsubscribeGroup( required numeric id, string name = '', string description = '', required boolean isDefault ) {
    var body = {
      'is_default' : isDefault
    };
    if ( arguments.name.len() )
      body[ 'name' ] = name;
    if ( arguments.description.len() )
      body[ 'description' ] = description;

    return apiCall( 'PATCH', '/asm/groups/#id#', {}, body );
  }

  /**
  * https://sendgrid.api-docs.io/v3.0/suppressions-unsubscribe-groups/delete-a-suppression-group
  * @hint Delete a suppression group.
  */
  public struct function deleteUnsubscribeGroup( required numeric id ) {
    return apiCall( 'DELETE', '/asm/groups/#id#' );
  }


  /**
  * https://sendgrid.api-docs.io/v3.0/email-address-validation/validate-an-email
  * https://sendgrid.com/docs/ui/managing-contacts/email-address-validation/
  * @hint Validates an email
  * @email Email address to validate
  * @source One word classifier for the validation
  */
  public struct function validateEmail( required string email, string source = '' ) {
    var body = {
      'email': arguments.email,
      'source': arguments.source
    }

    if( !len( variables.emailValidationApiKey ) ) {
      throw( "Use of email validation endpoint requires a separate API key. Please read the documentation for further details.");
    }

    var headers = {
      'Authorization' : 'Bearer #variables.emailValidationApiKey#'
    };
    return apiCall( 'POST', '/validations/email', {}, body, headers );
  }


  // PRIVATE FUNCTIONS
  private struct function apiCall(
    required string httpMethod,
    required string path,
    struct queryParams = { },
    any body = '',
    struct headers = { } )  {

    var fullApiPath = variables.baseUrl & path;
    var requestHeaders = getBaseHttpHeaders();
    requestHeaders.append( headers, true );

    var requestStart = getTickCount();
    var apiResponse = makeHttpRequest( httpMethod = httpMethod, path = fullApiPath, queryParams = queryParams, headers = requestHeaders, body = body );

    var result = {
      'responseTime' = getTickCount() - requestStart,
      'statusCode' = listFirst( apiResponse.statuscode, " " ),
      'statusText' = listRest( apiResponse.statuscode, " " )
    };

    var deserializedFileContent = {};

    if ( isJson( apiResponse.fileContent ) )
      deserializedFileContent = deserializeJSON( apiResponse.fileContent );

    //needs to be cusomtized by API integration for how errors are returned
    if ( result.statusCode >= 400 ) {
      if ( isStruct( deserializedFileContent ) )
        result.append( deserializedFileContent );
    }

    //stored in data, because some responses are arrays and others are structs
    result[ 'data' ] = deserializedFileContent;

    if ( variables.includeRaw ) {
      result[ 'raw' ] = {
        'method' : ucase( httpMethod ),
        'path' : fullApiPath,
        'params' : serializeJSON( queryParams ),
        'response' : apiResponse.fileContent,
        'responseHeaders' : apiResponse.responseheader
      };
    }

    return result;
  }

  private struct function getBaseHttpHeaders() {
    return {
      'Accept' : 'application/json',
      'Content-Type' : 'application/json',
      'User-Agent' : 'sendgrid.cfc/#variables._sendgridcfc_version# (ColdFusion)',
      'Authorization' : 'Bearer #variables.apiKey#'
    };
  }

  private any function makeHttpRequest(
    required string httpMethod,
    required string path,
    struct queryParams = { },
    struct headers = { },
    any body = ''
  ) {
    var result = '';

    var fullPath = path & ( !queryParams.isEmpty()
      ? ( '?' & parseQueryParams( queryParams, false ) )
      : '' );

    var requestHeaders = parseHeaders( headers );
    var requestBody = parseBody( body );

    cfhttp( url = fullPath, method = httpMethod, result = 'result', timeout = variables.httpTimeout ) {

      for ( var header in requestHeaders ) {
        cfhttpparam( type = "header", name = header.name, value = header.value );
      }

      if ( arrayFindNoCase( [ 'POST','PUT','PATCH','DELETE' ], httpMethod ) && isJSON( requestBody ) )
        cfhttpparam( type = "body", value = requestBody );

    }
    return result;
  }

  /**
  * @hint convert the headers from a struct to an array
  */
  private array function parseHeaders( required struct headers ) {
    var sortedKeyArray = headers.keyArray();
    sortedKeyArray.sort( 'textnocase' );
    var processedHeaders = sortedKeyArray.map(
      function( key ) {
        return { name: key, value: trim( headers[ key ] ) };
      }
    );
    return processedHeaders;
  }

  /**
  * @hint converts the queryparam struct to a string, with optional encoding and the possibility for empty values being pass through as well
  */
  private string function parseQueryParams( required struct queryParams, boolean encodeQueryParams = true, boolean includeEmptyValues = true ) {
    var sortedKeyArray = queryParams.keyArray();
    sortedKeyArray.sort( 'text' );

    var queryString = sortedKeyArray.reduce(
      function( queryString, queryParamKey ) {
        var encodedKey = encodeQueryParams
          ? encodeUrl( queryParamKey )
          : queryParamKey;
        if ( !isArray( queryParams[ queryParamKey ] ) ) {
          var encodedValue = encodeQueryParams && len( queryParams[ queryParamKey ] )
            ? encodeUrl( queryParams[ queryParamKey ] )
            : queryParams[ queryParamKey ];
        } else {
          var encodedValue = encodeQueryParams && ArrayLen( queryParams[ queryParamKey ] )
            ?  encodeUrl( serializeJSON( queryParams[ queryParamKey ] ) )
            : queryParams[ queryParamKey ].toList();
          }
        return queryString.listAppend( encodedKey & ( includeEmptyValues || len( encodedValue ) ? ( '=' & encodedValue ) : '' ), '&' );
      }, ''
    );

    return queryString.len() ? queryString : '';
  }

  private string function parseBody( required any body ) {
    if ( isStruct( body ) || isArray( body ) )
      return serializeJson( body );
    else if ( isJson( body ) )
      return body;
    else
      return '';
  }

  private string function encodeUrl( required string str, boolean encodeSlash = true ) {
    var result = replacelist( urlEncodedFormat( str, 'utf-8' ), '%2D,%2E,%5F,%7E', '-,.,_,~' );
    if ( !encodeSlash ) result = replace( result, '%2F', '/', 'all' );

    return result;
  }

  private numeric function returnUnixTimestamp( required any dateToConvert ) {
    return dateDiff( "s", variables.utcBaseDate, dateToConvert );
  }

}
