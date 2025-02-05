The `Athena::MIME` component allows manipulating the MIME messages used to send emails and provides utilities related to MIME types.

[MIME](https://en.wikipedia.org/wiki/MIME) (Multipurpose Internet Mail Extensions) is an Internet standard that extends the original basic format of emails to support features like:

* Headers and text contents using non-ASCII characters;
* Message bodies with multiple parts (e.g. HTML and plain text contents);
* Non-text attachments: audio, video, images, PDF, etc.

The entire MIME standard is complex and huge, but this component abstracts all that complexity to provide two ways of creating MIME messages:

* A high-level API based on the [AMIME::Email][] class to quickly create email messages with all the common features
* A low-level API based on the [AMIME::Message][] class to have absolute control over every single part of the email message

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-mime:
    github: athena-framework/mime
    version: ~> 0.1.0
```

## Usage

The [AMIME::Email][] class provides fluent setters to allow constructing an email with the desired information:

```crystal
email = AMIME::Email
  .new
  .from("me@example.com")
  .to("you@example.com")
  .cc("them@example.com")
  .bcc("other@example.com")
  .reply_to("me@example.com")
  .priority(:high)
  .subject("Important Notification")
  .text("Lorem ipsum...")
  .html("<h1>Lorem ipsum</h1> <p>...</p>")
  .attach_from_path("/path/to/file.pdf", "my-attachment.pdf")
  .embed_from_path("/path/to/logo.png")
```

See the API docs for that type for more information.
This component only handles creating the email messages. From here you would need to pass it along to another shard/component to actually send it.

### Creating Raw Email Messages

For most use cases, the `AMIME::Email` type would work just fine.
However some applications may require total control over every part of the email.

Consider a message that includes some HTMl and textual content, a single PNG embedded image, and a PDF file attachment.
The MIME standard allows constructing this message in different ways, but most commonly would be like:

```txt
multipart/mixed
├── multipart/related
│   ├── multipart/alternative
│   │   ├── text/plain
│   │   └── text/html
│   └── image/png
└── application/pdf
```

This is the purpose of each MIME message part:

* `multipart/alternative`: used when two or more parts are alternatives of the same (or very similar) content. The preferred format must be added last.
* `multipart/mixed`: used to send different content types in the same message, such as when attaching files.
* `multipart/related`: used to indicate that each message part is a component of an aggregate whole. The most common usage is to display images embedded in the message contents.

You must keep all of the above in mind when using the low-level `AMIME::Message` class to construct an email.

```crystal
headers = AMIME::Header::Collection
  .new
  .add_mailbox_list_header("from", {"me@example.com"})
  .add_mailbox_list_header("to", {"you@example.com"})
  .add_text_header("subject", "Important Notification")

text_content = AMIME::Part::Text.new "text content"
html_content = AMIME::Part::Text.new "html content", sub_type: "html"
body = AMIME::Part::Multipart::Alternative.new text_content, html_content

email = AMIME::Message.new headers, body
```

Embedding images and attaching files is possible by creating the appropriate email multi parts:

```crystal
headers = AMIME::Header::Collection
  .new
  .add_mailbox_list_header("from", {"me@example.com"})
  .add_mailbox_list_header("to", {"you@example.com"})
  .add_text_header("subject", "Important Notification")

embedded_image = AMIME::Part::Data.from_path "#{__DIR__}/../spec/fixtures/mimetypes/test.gif", content_type: "image/png"
image_cid = embedded_image.content_id

attached_file = AMIME::Part::Data.from_path "#{__DIR__}/../spec/fixtures/mimetypes/abc.csv", content_type: "image/png"

text_content = AMIME::Part::Text.new "text content"
html_content = AMIME::Part::Text.new %(<img src="cid:#{image_cid}"/> <h1>Lorem ipsum</h1> <p>...</p>), nil, "html"

body_content = AMIME::Part::Multipart::Alternative.new text_content, html_content
body = AMIME::Part::Multipart::Related.new body_content, {embedded_image}

message_parts = AMIME::Part::Multipart::Mixed.new body, attached_file

email = AMIME::Message.new headers, message_parts
```
