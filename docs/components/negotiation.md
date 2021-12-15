As mentioned in the [view event](/components/#4-view-event) documentation; this event is emitted whenever a controller action does _NOT_ return an `ATH::Response`, with this value being JSON serialized by default. The [Negotiation][Athena::Negotiation] component enhances the view layer of Athena by enabling [content negotiation](https://tools.ietf.org/html/rfc7231#section-5.3) support; making it possible to write format agnostic controllers by placing a layer of abstraction between the controller and generation of the final response content. Or in other words allow having the same controller action be rendered based on the request's [Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept) `HTTP` header and the format priority configuration.

## Configuration

See the [config](config.md) component documentation for an overview on how configuration is handled in Athena.

### Negotiation

The content negotiation logic is disabled by default, but can be easily enabled by redefining [ATH::Config::ContentNegotiation.configure][] with the desired configuration. Content negotiation configuration is represented by an array of [Rules][ATH::Config::ContentNegotiation::Rule] used to describe allowed formats, their priorities, and how things should function if a unsupported format is requested.

For example, say we configured things like:

```crystal
def ATH::Config::ContentNegotiation.configure
  new(
    # Setting fallback_format to json means that instead of considering
    # the next rule in case of a priority mismatch, json will be used.
    Rule.new(priorities: ["json", "xml"], host: "api.example.com", fallback_format: "json"),
    # Setting fallback_format to false means that instead of considering
    # the next rule in case of a priority mismatch, a 406 will be returned.
    Rule.new(path: /^\/image/, priorities: ["jpeg", "gif"], fallback_format: false),
    # Setting fallback_format to nil (or not including it) means that
    # in case of a priority mismatch the next rule will be considered.
    Rule.new(path: /^\/admin/, priorities: ["xml", "html"]),
    # Setting a priority to */* basically means any format will be matched.
    Rule.new(priorities: ["text/html", "*/*"], fallback_format: "html"),
  )
end
```

Assuming an `accept` header with the value `text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8,application/json`: a request made to `/foo` from the `api.example.com` hostname; the request format would be `json`. If the request was not made from that hostname; the request format would be `html`. The rules can be as complex or as simple as needed depending on the use case of your application.

### View Handler

The [ATH::View::ViewHandler][] is responsible for generating an [ATH::Response][] in the format determined by the [ATH::Listeners::Format][], otherwise falling back on the request's [format][ATH::Request#request_format], defaulting to `json`. The view handler has a few configurable options that can be customized if so desired. This can be achieved via redefining [Athena::Framework::Config::ViewHandler.configure][].

```crystal
def ATH::Config::ViewHandler.configure : ATH::Config::ViewHandler
  new(
    # The HTTP::Status to use if there is no response body, defaults to 204.
    empty_content_status: :im_a_teapot,
    # If `nil` values should be serialized, defaults to false.
    emit_nil: true    
  )
end
```

## Usage

### Views

An [ATH::View][] is intended to act as an in between returning raw data and an [ATH::Response][]. In other words, it still invokes the [view](README.md#4-view-event) event, but allows customizing the response's status and headers. Convenience methods are defined in the base controller type to make creating views easier. E.g. [ATH::Controller#view][].

### View Format Handlers

By default Athena uses `json` as the default response format. However it is possible to extend the [ATH::View::ViewHandler][] to support additional, and even custom, formats. This is achieved by creating an [ATH::View::FormatHandlerInterface][] instance that defines the logic needed to turn an [ATH::View][] into an [ATH::Response][].

The implementation can be as simple/complex as needed for the given format. Official handlers could be provided in the future for common formats such as `html`, probably via an integration with some form of tempting engine utilizing [custom annotations](config.md#custom-annotations) to specify the format.

### Adding/Customizing Formats

[ATH::Request::FORMATS][] represents the formats supported by default. However this list is not exhaustive and may need altered application to application; such as [registering][Athena::Framework::Request.register_format] new formats.

## Example

The following is a demonstration of how the various negotiation features can be used in conjunction. The example includes:

1. Defining a custom [ATH::View::ViewHandler][] for the `csv` format.
1. Enabling content negotiation, supporting `json` and `csv` formats, falling back to `json`.
1. An endpoint returning an [ATH::View][] that sets a custom HTTP status.

```crystal
require "athena"
require "csv"

# An interface to denote a type can provide its data in CSV format.
#
# An easier/more robust implementation can probably be thought of,
# however this is mainly for demonstration purposes.
module CSVRenderable
  abstract def to_csv(builder : CSV::Builder) : Nil
end

# Define an example entity type.
record User, id : Int64, name : String, email : String do
  include CSVRenderable
  include JSON::Serializable

  # Define the headers this type has.
  def self.headers : Enumerable(String)
    {
      "id",
      "name",
      "email",
    }
  end

  def to_csv(builder : CSV::Builder) : Nil
    # Add the related values based on `self.`
    builder.row @id, @name, @email
  end
end

# Register our handler as a service.
@[ADI::Register]
class CSVFormatHandler
  # Implement the interface.
  include Athena::Framework::View::FormatHandlerInterface

  # :inherit:
  def call(view_handler : ATH::View::ViewHandlerInterface, view : ATH::ViewBase, request : ATH::Request, format : String) : ATH::Response
    view_data = view.data

    headers = if view_data.is_a? Enumerable
                typeof(view_data.first).headers
              else
                view_data.class.headers
              end

    data = if view_data.is_a? Enumerable
             view_data
           else
             {view_data}
           end

    # Assume each item has the same headers.
    content = CSV.build do |csv|
      csv.row headers

      data.each do |r|
        r.to_csv csv
      end
    end

    # Return an ATH::Response with the rendered CSV content.
    # Athena handles setting the proper content-type header based on the format.
    # But could be overridden here if so desired.
    ATH::Response.new content
  end

  # :inherit:
  def format : String
    "csv"
  end
end

# Configure the format listener.
def ATH::Config::ContentNegotiation.configure
  new(
    # Allow json and csv formats, falling back on json if an unsupported format is requested.
    Rule.new(priorities: ["json", "csv"], fallback_format: "json"),
  )
end

class ExampleController < ATH::Controller
  @[ATHA::Get("/users")]
  def get_users : ATH::View(Array(User))
    self.view([
      User.new(1, "Jim", "jim@example.com"),
      User.new(2, "Bob", "bob@example.com"),
      User.new(3, "Sally", "sally@example.com"),
    ], status: :im_a_teapot)
  end
end

ATH.run
```
