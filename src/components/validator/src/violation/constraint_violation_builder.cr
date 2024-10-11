require "./constraint_violation_builder_interface"

# Basic implementation of `AVD::Violation::ConstraintViolationBuilderInterface`.
class Athena::Validator::Violation::ConstraintViolationBuilder
  include Athena::Validator::Violation::ConstraintViolationBuilderInterface

  @plural : Int32?
  @cause : String?

  protected def initialize(
    @violations : AVD::Violation::ConstraintViolationListInterface,
    @constraint : AVD::Constraint?,
    @message : String,
    @parameters : Hash(String, String),
    @root_container : AVD::Container,
    @property_path : String,
    @invalid_value : AVD::Container,
  )
  end

  # :inherit:
  def add : Nil
    # Split and determine the message to use based on plural value
    translated_message = if !(count = @plural).nil? && @message.includes? '|'
                           parts = @message.split('|')
                           # TODO: Support more robust translations
                           count == 1 ? parts.first : parts[1]
                         else
                           @message
                         end

    rendered_message = translated_message.gsub(/(?:{{ \w+ }})+/, @parameters)

    @violations.add AVD::Violation::ConstraintViolation.new(
      rendered_message,
      @message,
      @parameters,
      @root_container,
      @property_path,
      @invalid_value,
      @plural,
      @code,
      @constraint,
      @cause
    )
  end

  # :inherit:
  def add_parameter(key : String, value : _) : AVD::Violation::ConstraintViolationBuilderInterface
    @parameters[key] = value.to_s

    self
  end

  # :inherit:
  def at_path(path : String) : AVD::Violation::ConstraintViolationBuilderInterface
    @property_path = AVD::PropertyPath.append @property_path, path

    self
  end

  # :inherit:
  def cause(@cause : String?) : AVD::Violation::ConstraintViolationBuilderInterface
    self
  end

  # :inherit:
  def code(@code : String?) : AVD::Violation::ConstraintViolationBuilderInterface
    self
  end

  # :inherit:
  def constraint(@constraint : AVD::Constraint?) : AVD::Violation::ConstraintViolationBuilderInterface
    self
  end

  # :inherit:
  def invalid_value(value : _) : AVD::Violation::ConstraintViolationBuilderInterface
    @invalid_value = AVD::ValueContainer.new value

    self
  end

  # :inherit:
  def plural(number : Int32) : AVD::Violation::ConstraintViolationBuilderInterface
    @plural = number
    self
  end

  # :inherit:
  def set_parameters(@parameters : Hash(String, String)) : AVD::Violation::ConstraintViolationBuilderInterface
    self
  end
end
