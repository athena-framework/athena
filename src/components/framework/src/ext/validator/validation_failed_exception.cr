# Wraps an `AVD::Violation::ConstraintViolationListInterface` as an `ATH::Exception::UnprocessableEntity`; exposing the violations within the response body.
class Athena::Validator::Exception::ValidationFailed < Athena::Framework::Exception::UnprocessableEntity
  getter violations : Athena::Validator::Violation::ConstraintViolationListInterface

  def initialize(violations : AVD::Violation::ConstraintViolationInterface | AVD::Violation::ConstraintViolationListInterface, cause : ::Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    if violations.is_a? AVD::Violation::ConstraintViolationInterface
      violations = AVD::Violation::ConstraintViolationList.new [violations]
    end

    @violations = violations

    super "Validation failed", cause, headers
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
