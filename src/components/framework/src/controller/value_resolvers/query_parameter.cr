# Attempts to resolve the value from the request's query parameters for any parameter with the `ATHA::MapQueryParameter` annotation.
# Supports most primitive types, as well as arrays of most primitive types, and enums.
#
# The name of the query parameter is assumed to be the same as the controller action parameter's name.
# This can be customized via the `name` field on the annotation.
#
# If the controller action parameter is not-nilable nor has a default value and is missing, an `ATH::Exception::NotFound` exception will be raised by default.
# Similarly, an exception will be raised if the value fails to be converted to the expected type.
# The specific type of exception can be customized via the `validation_failed_status` field on the annotation.
#
# ```
# require "athena"
#
# enum Color
#   Red
#   Green
#   Blue
# end
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get("/")]
#   def index(
#     @[ATHA::MapQueryParameter] ids : Array(Int32),
#     @[ATHA::MapQueryParameter(name: "firstName")] first_name : String,
#     @[ATHA::MapQueryParameter] required : Bool,
#     @[ATHA::MapQueryParameter] age : Int32,
#     @[ATHA::MapQueryParameter] color : Color,
#     @[ATHA::MapQueryParameter] category : String = "",
#     @[ATHA::MapQueryParameter] theme : String? = nil,
#   ) : Nil
#     ids        # => [1, 2]
#     first_name # => "Jon"
#     required   # => false
#     age        # => 123
#     color      # => Color::Blue
#     category   # => ""
#     theme      # => nil
#   end
# end
#
# ATH.run
#
# # GET /?ids=1&ids=2&firstName=Jon&required=false&age=123&color=blue
# ```
@[ADI::Register(tags: [{name: ATHR::Interface::TAG, priority: 110}])]
struct Athena::Framework::Controller::ValueResolvers::QueryParameter
  include Athena::Framework::Controller::ValueResolvers::Interface

  # Enables the `ATHR::QueryParameter` resolver for the parameter this annotation is applied to.
  # See the related resolver documentation for more information.
  configuration ::Athena::Framework::Annotations::MapQueryParameter,
    name : String? = nil,
    validation_failed_status : HTTP::Status = :not_found

  # :inherit:
  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata)
    return unless ann = parameter.annotation_configurations[ATHA::MapQueryParameter]?

    name = ann.name || parameter.name
    validation_failed_status = ann.validation_failed_status

    params = request.query_params

    unless params.has_key? name
      return if parameter.nilable? || parameter.has_default?

      raise ATH::Exception::HTTPException.from_status validation_failed_status, "Missing query parameter: '#{name}'."
    end

    value = if parameter.instance_of? Array
              params.fetch_all name
            else
              params[name]
            end

    begin
      parameter.type.from_parameter value
    rescue ex : ArgumentError
      # Catch type cast errors and bubble it up as a BadRequest
      raise ATH::Exception::HTTPException.from_status validation_failed_status, "Invalid query parameter: '#{name}'.", cause: ex
    end
  end
end
