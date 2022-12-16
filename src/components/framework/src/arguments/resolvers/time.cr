@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 105}])]
# Attempts to parse a date(time) string into a `::Time` instance.
#
# Optionally allows specifying the *format* and *location* to use when parsing the string via the `ATHR::Time::Format` annotation.
# If no *format* is specified, defaults to [RFC 3339](https://crystal-lang.org/api/Time.html#parse_rfc3339%28time:String%29-class-method).
# Defaults to `UTC` if no *location* is specified with the annotation.
#
# Raises an `ATH::Exceptions::BadRequest` if the date(time) string could not be parsed.
#
# TIP: The format can be anything supported via [Time::Format](https://crystal-lang.org/api/Time/Format.html).
#
# ```
# require "athena"
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get(path: "/event/{start_time}/{end_time}")]
#   def event(
#     @[ATHR::Time::Format("%F", location: Time::Location.load("Europe/Berlin"))]
#     start_time : Time,
#     end_time : Time
#   ) : Nil
#     start_time # => 2020-04-07 00:00:00.0 +02:00 Europe/Berlin
#     end_time   # => 2020-04-08 12:34:56.0 UTC
#   end
# end
#
# ATH.run
#
# # GET /event/2020-04-07/2020-04-08T12:34:56Z
# ```
struct Athena::Framework::Arguments::Resolvers::Time
  include Athena::Framework::Arguments::Resolvers::Interface

  # Allows customing the time format and/or location used to parse the string datetime as part of the `ATHR::Time` resolver.
  # See the related resolver documentation for more information.
  configuration Format, format : String? = nil, location : ::Time::Location = ::Time::Location::UTC

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : ::Time?
    return unless argument.instance_of? ::Time

    if value = request.attributes.get? argument.name, ::Time?
      return value
    end

    return unless (value = request.attributes.get? argument.name, String?)

    if !(configuration = argument.annotation_configurations[Format]?) || !(format = configuration.format)
      return ::Time.parse_rfc3339(value)
    end

    ::Time.parse value, format, configuration.location
  rescue ex : ::Time::Format::Error
    raise ATH::Exceptions::BadRequest.new "Invalid date(time) for parameter '#{argument.name}'."
  end
end
