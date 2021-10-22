require "./unprocessable_entity"

class Athena::Framework::Exceptions::InvalidParameter < Athena::Framework::Exceptions::UnprocessableEntity
  getter parameter : ATH::Params::ParamInterface
  getter violations : AVD::Violation::ConstraintViolationListInterface

  def self.with_violations(parameter : ATH::Params::ParamInterface, violations : AVD::Violation::ConstraintViolationListInterface) : self
    message = String.build do |str|
      violations.each do |violation|
        invalid_value = violation.invalid_value

        str.puts "Parameter '#{parameter.name}#{violation.property_path}' of value '#{invalid_value}' violated a constraint: '#{violation.message}'"
      end
    end

    new parameter, violations, message
  end

  def initialize(@parameter : ATH::Params::ParamInterface, @violations : AVD::Violation::ConstraintViolationListInterface, message : String, cause : Exception? = nil, headers : HTTP::Headers = HTTP::Headers.new)
    super message, cause, headers
  end
end
