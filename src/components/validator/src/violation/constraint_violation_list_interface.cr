# A wrapper type around an `Array(AVD::ConstraintViolationInterface)`.
module Athena::Validator::Violation::ConstraintViolationListInterface
  # Adds the provided *violation* to `self`.
  abstract def add(violation : AVD::Violation::ConstraintViolationInterface) : Nil

  # Adds each of the provided *violations* to `self`.
  abstract def add(violations : AVD::Violation::ConstraintViolationListInterface) : Nil

  # Returns `true` if a violation exists at the provided *index*, otherwise `false`.
  abstract def has?(index : Int) : Bool

  # Sets the provided *violation* at the provided *index*.
  abstract def set(index : Int, violation : AVD::Violation::ConstraintViolationInterface) : Nil

  # Returns the number of violations in `self`.
  abstract def size : Int

  # Returns the violation at the provided *index*.
  abstract def remove(index : Int) : Nil

  # Returns a `JSON` representation of `self`.
  abstract def to_json(builder : JSON::Builder) : Nil

  # Returns a string representation of `self`.
  abstract def to_s(io : IO) : Nil
end
