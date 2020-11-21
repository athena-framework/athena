class Athena::Routing::Exceptions::InvalidParameter < Athena::Routing::Exceptions::BadRequest
  getter parameter : ART::Params::ParamInterfaceBase
  getter violations : AVD::Violation::ConstraintViolationListInterface

  def self.with_violations(parameter : ART::Params::ParamInterfaceBase, violations : AVD::Violation::ConstraintViolationListInterface) : self
    message = String.build do |str|
      violations.each do |violation|
        invalid_value = violation.invalid_value

        str << "Parameter '#{parameter.name}' of value '#{invalid_value}' violated a constraint: '#{violation.message}'"
      end
    end

    new parameter, violations, message
  end

  def initialize(@parameter : ART::Params::ParamInterfaceBase, @violations : AVD::Violation::ConstraintViolationListInterface, message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super message, cause, headers
  end
end
