class Athena::Validator::Exceptions::ValidationFailedError < Athena::Routing::Exceptions::UnprocessableEntity
  getter violations : Athena::Validator::Violation::ConstraintViolationList

  def initialize(violations : AVD::Violation::ConstraintViolationInterface | AVD::Violation::ConstraintViolationList, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
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
