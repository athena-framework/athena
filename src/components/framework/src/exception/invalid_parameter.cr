require "./unprocessable_entity"

class Athena::Framework::Exception::InvalidParameter < Athena::Framework::Exception::UnprocessableEntity
  getter parameter : ATH::Params::ParamInterface
  getter violations : AVD::Violation::ConstraintViolationListInterface

  def self.with_violations(parameter : ATH::Params::ParamInterface, violations : AVD::Violation::ConstraintViolationListInterface) : self
    new parameter, violations, "Parameter '#{parameter.name}' is invalid."
  end

  def initialize(@parameter : ATH::Params::ParamInterface, @violations : AVD::Violation::ConstraintViolationListInterface, message : String, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super message, cause, headers
  end

  def to_json(builder : JSON::Builder) : Nil
    builder.object do
      builder.field "code", self.status_code
      builder.field "message", @message

      builder.field "errors" do
        @violations.to_json builder
      end
    end
  end
end
