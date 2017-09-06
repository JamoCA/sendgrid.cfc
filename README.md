# sendgridcfc
A CFML wrapper for the SendGrid API

This project borrows heavily from the API frameworks built by [jcberquist](https://github.com/jcberquist), such as [stripecfc](https://github.com/jcberquist/stripecfc), [xero-cfml](https://github.com/jcberquist/xero-cfml), and [aws-cfml](https://github.com/jcberquist/aws-cfml).

This is a very early stage API wrapper. Feel free to use the issue tracker to report bugs or suggest improvements!

# Quick Start (with helper)

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

## `helpers.mail` Reference Manual
This section documents every public method in the `helpers/mail.cfc` file.

Unless indicated, all methods are chainable. Top level parameters are referred to as "global" or "message level", as opposed to personalized parameters. As the SendGrid docs state: "Individual fields within the personalizations array will override any other global, or “message level”, parameters that are defined outside of personalizations."

### `from( required any email )`

### `replyTo( required any email )`

### `subject( required string subject )`
Sets the global subject. This may be overridden by personalizations[x].subject.

### `html( required string message )`
Convenience method for adding the text/html content

### `plain( required string message )`
Convenience method for adding the text/plain content

### `emailContent( required struct content, boolean doAppend = true )`
Method for setting any content mime-type. The default is that the new mime-type is appended to the Content array, but you can override this and have it prepended. This is used internally to ensure that `text/plain` precedes `text/html`, in accordance with the RFC specs, as enforced by SendGrid.

### `plainFromHtml( string message = '' )`
Convenience method for setting both `text/html` and `text/plain` at the same time. You can either pass in the HTML content as the message argument, and both will be set from it (using an internal method to strip the HTML for the plain text version), or you can call the method without an argument, after having set the HTML, and that will be used.

### `header( required any header, any value )`
Appends a single header to the global message's `headers` property. This can be overridden by a personalized header. 

You can set a header by providing the header and value separately, or by passing in a struct with a key/value pair; for example, `{ "X-my-application-name" : 'testing' }`.

### `headers( required struct headers )`
Sets the `headers` property for the global message. Headers can be overridden by a personalized header. If any headers are set, this method overwrites them.

### `categories( required any categories )`
Sets the category array for the global message. If categories are already set, this overwrites them. The argument can be passed in as an array or comma separated list. Lists will be converted to arrays

### `addCategory( required string category )`
Appends a single category to the global message category array

### `customArg( required any arg, any value )`
Appends a single custom argument on the global message's `custom_args` property. This can be overridden by a personalized custom argument.

You can set a custom argument by providing the argument's name and value separately, or by passing in a struct with a key/value pair; for example, `{ "Team": "Engineering" }`.

### `customArgs( required struct args )`
Sets the `custom_args` property for the global message. Custom arguments can be overridden by a personalized custom argument. If any custom arguments are set, this overwrites them.

### `to( required any email )`
Adds a **new** personalization envelope, with only the specified email address. The personalization can then be further customized with later commands. I found personalizations a little tricky. You can [read more here](https://sendgrid.com/docs/Classroom/Send/v3_Mail_Send/personalizations.html).

### `addTo( required any email )`
Adds an additional 'to' recipient to the **current** personalization envelope

### `addCC( required any email )`
Adds an additional 'cc' recipient to the **current** personalization envelope. You need to add a 'to' recipient before using this.

### `addBCC( required any email )`
Adds an additional 'bcc' recipient to the **current** personalization envelope. You need to add a 'to' recipient before using this.

### `withSubject ( required string subject )`
Sets the subject for the current personalization envelope. This overrides the global email subject for these recipients. A basic personalization envelope (with a 'to' recipient) needs to be in place before this can be added.

### `withHeader ( any header, any value )`
Functions like `header()`, except it adds the header to the **current** personalization envelope.

### `withSubstitution ( any substitution, any value )`
Adds a substitution ( "substitution_tag" : "value to substitute" ) to the **current** personalization envelope. You can add a substitution by providing the tag and value to substitute, or by passing in a struct.

### `build()`
The function that puts it all together and builds the body for `/mail/send`


## Notes

* Email address parameters can be passed in either as strings or structs.
  * When passed as a string, they can be in the format: Person \<name@email.com\>, in order to pass both name and email address.
  * When passed as a struct, the keys should be `email` and `name`, respectively. Only email is required.