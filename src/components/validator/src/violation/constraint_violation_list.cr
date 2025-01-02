require "./constraint_violation_list_interface"

# Basic implementation of `AVD::Violation::ConstraintViolationListInterface`.
struct Athena::Validator::Violation::ConstraintViolationList
  include Athena::Validator::Violation::ConstraintViolationListInterface
  include Indexable(Athena::Validator::Violation::ConstraintViolationInterface)

  @violations : Array(AVD::Violation::ConstraintViolationInterface) = [] of AVD::Violation::ConstraintViolationInterface

  def initialize(violations : Array(AVD::Violation::ConstraintViolationInterface) = [] of AVD::Violation::ConstraintViolationInterface)
    violations.each do |violation|
      add violation
    end
  end

  # Returns a new `AVD::Violation::ConstraintViolationInterface` that consists only of violations with the provided *error_code*.
  def find_by_code(error_code : String) : AVD::Violation::ConstraintViolationListInterface
    self.class.new @violations.select &.code.==(error_code)
  end

  # :inherit:
  def add(violation : AVD::Violation::ConstraintViolationInterface) : Nil
    @violations << violation
  end

  # :inherit:
  def add(violations : AVD::Violation::ConstraintViolationListInterface) : Nil
    @violations.concat violations
  end

  # :inherit:
  def has?(index : Int) : Bool
    !@violations[index]?.nil?
  end

  # :inherit:
  def remove(index : Int) : Nil
    @violations.delete_at index
  end

  # :inherit:
  def set(index : Int, violation : AVD::Violation::ConstraintViolationInterface) : Nil
    @violations[index] = violation
  end

  # :inherit:
  def size : Int
    @violations.size
  end

  # :inherit:
  def to_json(builder : JSON::Builder) : Nil
    builder.array do
      @violations.each do |violation|
        violation.to_json builder
      end
    end
  end

  # :inherit:
  def to_s(io : IO) : Nil
    @violations.each do |violation|
      violation.to_s io
    end
  end

  # :nodoc:
  @[AlwaysInline]
  def unsafe_fetch(index : Int) : AVD::Violation::ConstraintViolationInterface
    @violations[index]
  end
end
