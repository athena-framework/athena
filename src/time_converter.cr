require "./param_converter_interface"

# Converts a date(time) string into a `Time` instance.
#
# Optionally allows specifying the *format* and *location* to use when parsing the string.
# If no *format* is specified, defaults to [Time.rfc_3339](https://crystal-lang.org/api/Time.html#parse_rfc3339%28time:String%29-class-method).
# Defaults to `UTC` if no *location* is specified with the format.
#
# Raises an `ART::Exceptions::BadRequest` if the date(time) string could not be parsed.
#
# TIP: The format can be anything supported via [Time::Format](https://crystal-lang.org/api/Time/Format.html).
#
# ```
# require "athena"
#
# class ExampleController < ART::Controller
#   @[ARTA::Get(path: "/event/:start_time/:end_time")]
#   @[ARTA::ParamConverter("start_time", converter: ART::TimeConverter, format: "%F", location: Time::Location.load("Europe/Berlin"))]
#   @[ARTA::ParamConverter("end_time", converter: ART::TimeConverter)]
#   def event(start_time : Time, end_time : Time) : Nil
#     start_time # => 2020-04-07 00:00:00.0 +02:00 Europe/Berlin
#     end_time   # => 2020-04-08 12:34:56.0 UTC
#   end
# end
#
# ART.run
#
# # GET /event/2020-04-07/2020-04-08T12:34:56Z
# ```
@[ADI::Register]
struct Athena::Routing::TimeConverter < Athena::Routing::ParamConverterInterface
  configuration format : String? = nil, location : Time::Location = Time::Location::UTC

  # :inherit:
  def apply(request : ART::Request, configuration : Configuration) : Nil
    arg_name = configuration.name

    return unless request.attributes.has? arg_name

    value = request.attributes.get arg_name

    return if value.is_a?(Time) || !value.is_a?(String)

    time = (format = configuration.format) ? Time.parse(value, format, configuration.location) : Time.parse_rfc3339(value)

    request.attributes.set arg_name, time, Time
  rescue ex : Time::Format::Error
    raise ART::Exceptions::BadRequest.new "Invalid date(time) for argument '#{arg_name}'."
  end
end
