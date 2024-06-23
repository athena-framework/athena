require "../spec_helper"

private alias CONSTRAINT = AVD::Constraints::Unique

private record Foo

struct UniqueValidatorTest < AVD::Spec::ConstraintValidatorTestCase
  @[DataProvider("valid_values")]
  def test_valid_values(value : _) : Nil
    self.validator.validate value, self.new_constraint
    self.assert_no_violation
  end

  @[DataProvider("invalid_values")]
  def test_invalid_values(value : _) : Nil
    self.validator.validate value, self.new_constraint message: "my_message"
    self.assert_violation "my_message", CONSTRAINT::IS_NOT_UNIQUE_ERROR, value
  end

  def test_invalid_type : Nil
    expect_raises AVD::Exception::UnexpectedValueError, "Expected argument of type 'Indexable', 'Int32' given." do
      self.validator.validate 123, new_constraint message: "my_message"
    end
  end

  def valid_values : NamedTuple
    {
      nil:             {nil},
      empty_array:     {[] of Int32},
      single_nil:      {[nil]},
      single_integer:  {[1]},
      single_string:   {["foo"]},
      single_object:   {[Foo.new]},
      single_tuple:    { {1} },
      unique_booleans: {[true, false]},
      unique_integers: {[1, 2, 3, 4, 5, 6]},
      unique_floats:   {[1.0, 2.0, 3.0]},
      unique_strings:  {["a", "b", "c"]},
      unique_arrays:   {[[1, 2], [2, 4], [4, 6]]},
      unique_tuples:   { { {1, 2}, {2, 4}, {4, 6} } },
      unique_mixed:    {["a", true, 10.0, 7_u8]},
      unique_dequeue:  {Deque{1, 4, 9}},
    }
  end

  def invalid_values : NamedTuple
    object = Foo.new

    {
      not_unique_nil:      {[nil, nil]},
      not_unique_booleans: {[true, true]},
      not_unique_integers: {[1, 2, 2, 3]},
      not_unique_floats:   {[0.1, 0.2, 0.1]},
      not_unique_strings:  {["a", "a"]},
      not_unique_arrays:   {[[1, 1], [2, 3], [1, 1]]},
      not_unique_objects:  {[object, object]},
      not_unique_tuples:   { { {1, 1}, {2, 3}, {1, 1} } },
      not_unique_mixed:    {["a", true, 10.0, 7_u8, "a"]},
      not_unique_dequeue:  {Deque{1, 5, 1}},
    }
  end

  private def create_validator : AVD::ConstraintValidatorInterface
    CONSTRAINT::Validator.new
  end

  private def constraint_class : AVD::Constraint.class
    CONSTRAINT
  end
end
