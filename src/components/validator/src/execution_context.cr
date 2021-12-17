require "./validator/validator_interface"
require "./execution_context_interface"

# Basic implementation of `AVD::ExecutionContextInterface`.
class Athena::Validator::ExecutionContext(Root)
  include Athena::Validator::ExecutionContextInterface

  # :inherit:
  getter constraint : AVD::Constraint?

  # :inherit:
  getter group : String?

  # :inherit:
  getter validator : AVD::Validator::ValidatorInterface

  # :inherit:
  getter violations : AVD::Violation::ConstraintViolationList = AVD::Violation::ConstraintViolationList.new

  # :inherit:
  @property_path : String = ""

  # :inherit:
  getter metadata : AVD::Metadata::MetadataInterface? = nil

  # The value that is currently being validated.
  @value_container : AVD::Container = AVD::ValueContainer.new(nil)

  # :inherit:
  getter root : Root

  # The object that is currently being validated.
  getter object_container : AVD::Container = AVD::ValueContainer.new(nil)

  def initialize(@validator : AVD::Validator::ValidatorInterface, @root : Root); end

  # :nodoc:
  def constraint=(@constraint : AVD::Constraint?); end

  # :nodoc:
  def group=(@group : String?); end

  # :inherit:
  def value
    @value_container.value
  end

  # :inherit:
  def object
    @object_container.value
  end

  # :inherit:
  def class_name
    @metadata.try &.class_name
  end

  # :inherit:
  def property_name : String?
    @metadata.try &.name
  end

  # :inherit:
  def property_path(path : String = "") : String
    AVD::PropertyPath.append @property_path, path
  end

  # :nodoc:
  def set_node(value : _, object : _, metadata : AVD::Metadata::MetadataInterface?, property_path : String) : Nil
    @value_container = AVD::ValueContainer.new value
    @object_container = AVD::ValueContainer.new object
    @metadata = metadata
    @property_path = property_path
  end

  # :inherit:
  def add_violation(message : String, code : String) : Nil
    self.build_violation(message, code).add
  end

  # :inherit:
  def add_violation(message : String, code : String, value : _) : Nil
    self.build_violation(message, code, value).add
  end

  # :inherit:
  def add_violation(message : String, parameters : Hash(String, String) = {} of String => String) : Nil
    self.build_violation(message, parameters).add
  end

  # :inherit:
  def build_violation(message : String, code : String) : AVD::Violation::ConstraintViolationBuilderInterface
    self.build_violation(message).code(code)
  end

  # :inherit:
  def build_violation(message : String, code : String, value : _) : AVD::Violation::ConstraintViolationBuilderInterface
    self.build_violation(message).code(code).add_parameter("{{ value }}", value)
  end

  # :inherit:
  def build_violation(message : String, parameters : Hash(String, String) = {} of String => String) : AVD::Violation::ConstraintViolationBuilderInterface
    AVD::Violation::ConstraintViolationBuilder.new(
      @violations,
      @constraint,
      message,
      parameters,
      @root,
      @property_path,
      @value_container,
    )
  end
end
