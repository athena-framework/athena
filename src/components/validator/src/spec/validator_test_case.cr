# :nodoc:
abstract struct Athena::Validator::Spec::ValidatorTestCase < AVD::Spec::AbstractValidatorTestCase
  getter! validator : AVD::Validator::ValidatorInterface

  def initialize
    super

    @validator = self.create_validator @metadata_factory
  end

  abstract def create_validator(metadata_factory : AVD::Metadata::MetadataFactoryInterface) : AVD::Validator::ValidatorInterface

  def validate(value, constraints = nil, groups = nil) : AVD::Violation::ConstraintViolationListInterface
    self.validator.validate value, constraints, groups
  end

  def validate_property(object, property_name, groups = nil) : AVD::Violation::ConstraintViolationListInterface
    self.validator.validate_property object, property_name, groups
  end

  def validate_property_value(object, property_name, value, groups = nil) : AVD::Violation::ConstraintViolationListInterface
    self.validator.validate_property_value object, property_name, value, groups
  end

  def test_validate_constraint_without_group : Nil
    self.validate(nil, AVD::Constraints::NotNil.new).size.should eq 1
  end

  def test_validate_empty_array_as_constraint : Nil
    self.validate(nil, [] of AVD::Constraint).should be_empty
  end

  def test_validate_group_sequence_aborts_after_failed_group : Nil
    object = Entity.new

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message1"
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message2"
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: AVD::Constraints::Callback::CallbackProc.new { }, groups: ["group1"]
    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: ["group2"]
    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: ["group3"]

    violations = self.validate object, AVD::Constraints::Valid.new, AVD::Constraints::GroupSequence.new(["group1", "group2", "group3"])

    violations.size.should eq 1
    violations.first.message.should eq "message1"
  end

  def test_validate_group_sequence_includes_sub_objects : Nil
    object = Entity.new
    object.sub_object = SubEntity.new

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message1"
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message2"
    end

    @metadata.add_property_constraint "sub_object", AVD::Constraints::Valid.new
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: ["group1"]
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: ["group2"]

    violations = self.validate object, AVD::Constraints::Valid.new, AVD::Constraints::GroupSequence.new(["group1", "Athena::Validator::Spec::AbstractValidatorTestCase::Entity"])

    violations.size.should eq 1
    violations.first.message.should eq "message1"
  end

  def test_validate_in_separate_context : Nil
    object = Entity.new
    object.sub_object = SubEntity.new

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |value, context|
      value = value.get Entity

      violations = context.validator.validate value.sub_object, AVD::Constraints::Valid.new, "group"

      violations.size.should eq 1
      violation = violations.first

      violation.message.should eq "message value"
      violation.message_template.should eq "message {{ value }}"
      violation.parameters.should eq({"{{ value }}" => "value"})
      violation.property_path.should be_empty

      violation.root.should eq value.sub_object
      violation.invalid_value.should eq value.sub_object
      violation.plural.should be_nil
      violation.code.should be_nil

      context.add_violation "different violation"
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      context.class_name.should eq SubEntity
      context.property_name.should be_nil
      context.property_path.should be_empty
      context.group.should eq "group"
      context.root.should eq object.sub_object
      context.value.should eq object.sub_object
      value.should eq object.sub_object

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: "group"
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: "group"

    violations = self.validate object, AVD::Constraints::Valid.new, "group"

    violations.size.should eq 1
    violations.first.message.should eq "different violation"
  end

  def test_validate_in_context : Nil
    object = Entity.new
    object.sub_object = SubEntity.new

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |value, context|
      previous_value = context.value
      previous_object = context.object
      previous_metadata = context.metadata
      previous_path = context.property_path
      previous_group = context.group

      context
        .validator
        .in_context(context)
        .at_path("subpath")
        .validate(value.get(Entity).sub_object)

      # Context changes shouldn't leak from #validate.
      previous_value.should eq context.value
      previous_object.should eq context.object
      previous_metadata.should eq context.metadata
      previous_path.should eq context.property_path
      previous_group.should eq context.group
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      context.class_name.should eq SubEntity
      context.property_name.should be_nil
      context.property_path.should eq "subpath"
      context.group.should eq "group"
      context.metadata.should eq @sub_object_metadata
      context.root.should eq object
      context.value.should eq object.sub_object
      value.should eq object.sub_object

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: "group"
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: "group"

    violations = self.validate object, AVD::Constraints::Valid.new, "group"

    violations.size.should eq 1
    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should eq "subpath"
    violation.root.should eq object
    violation.invalid_value.should eq object.sub_object
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_hash_in_context : Nil
    object = Entity.new
    object.sub_object = SubEntity.new

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |value, context|
      previous_value = context.value
      previous_object = context.object
      previous_metadata = context.metadata
      previous_path = context.property_path
      previous_group = context.group

      context
        .validator
        .in_context(context)
        .at_path("subpath")
        .validate({"key" => value.get(Entity).sub_object})

      # Context changes shouldn't leak from #validate.
      previous_value.should eq context.value
      previous_object.should eq context.object
      previous_metadata.should eq context.metadata
      previous_path.should eq context.property_path
      previous_group.should eq context.group
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      context.class_name.should eq SubEntity
      context.property_name.should be_nil
      context.property_path.should eq "subpath[key]"
      context.group.should eq "group"
      context.metadata.should eq @sub_object_metadata
      context.root.should eq object
      context.value.should eq object.sub_object
      value.should eq object.sub_object

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: "group"
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: "group"

    violations = self.validate object, AVD::Constraints::Valid.new, "group"

    violations.size.should eq 1
    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should eq "subpath[key]"
    violation.root.should eq object
    violation.invalid_value.should eq object.sub_object
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_sub_object_with_cascade_disabled_by_default : Nil
    object = Entity.new
    object.sub_object = SubEntity.new

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, _context|
      fail "Callback should not have been invoked"
    end

    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: "group"

    self.validate(object, AVD::Constraints::Valid.new, "group").should be_empty
  end

  def test_validate_customized_violation : Nil
    object = Entity.new

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context
        .build_violation("message {{ value }}", "CODE", "value")
        .plural(2)
        .invalid_value("Invalid Value")
        .add
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback

    violations = self.validate object

    violations.size.should eq 1
    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should be_empty
    violation.root.should eq object
    violation.invalid_value.should eq "Invalid Value"
    violation.plural.should eq 2
    violation.code.should eq "CODE"
  end

  def ptest_validate_no_duplicate_violations_if_class_constraint_is_in_multiple_groups : Nil
    object = Entity.new

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message"
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group1", "group2"]

    self.validate(object, AVD::Constraints::Valid.new, groups: ["group1", "group2"]).size.should eq 1
  end

  def ptest_validate_no_duplicate_violations_if_property_constraint_is_in_multiple_groups : Nil
    object = Entity.new

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message"
    end

    @metadata.add_property_constraint "first_name", AVD::Constraints::Callback.new callback: callback, groups: ["group1", "group2"]

    self.validate(object, AVD::Constraints::Valid.new, groups: ["group1", "group2"]).size.should eq 1
  end

  def test_validate_fails_non_object_array_and_no_constraints : Nil
    expect_raises ArgumentError, "Could not validate values of type 'String' automatically.  Please provide a constraint." do
      self.validate "Foo"
    end
  end

  def test_validate_access_current_object : Nil
    called = false
    object = Entity.new
    object.first_name = "Fred"
    object.data_hash = {"first_name" => "Jon"}

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      called = true
      context.object.should eq object
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback
    @metadata.add_property_constraint "first_name", AVD::Constraints::Callback.new callback: callback
    @metadata.add_property_constraints({"data_hash" => AVD::Constraints::EqualTo.new({"first_name" => "Jon"})})

    self.validate object

    called.should be_true
  end

  def test_validate_constraint_is_passed_to_violation : Nil
    constraint = FailingConstraint.new

    violations = self.validate "foo", constraint

    violations.size.should eq 1
    violations.first.constraint.should eq constraint
  end

  def test_validate_sub_object_is_not_validated_if_group_in_valid_constraint_is_not_validated : Nil
    object = Entity.new
    object.first_name = ""
    sub_object = SubEntity.new
    sub_object.value = ""
    object.sub_object = sub_object

    @metadata.add_property_constraint "first_name", AVD::Constraints::NotBlank.new groups: "group1"
    @metadata.add_property_constraint "sub_object", AVD::Constraints::Valid.new groups: "group1"
    @sub_object_metadata.add_property_constraint "value", AVD::Constraints::NotBlank.new

    self.validate(object, nil, [] of String).should be_empty
  end

  def test_validate_sub_object_is_validated_if_group_in_valid_constraint_is_valided : Nil
    object = Entity.new
    object.first_name = ""
    sub_object = SubEntity.new
    sub_object.value = ""
    object.sub_object = sub_object

    @metadata.add_property_constraint "first_name", AVD::Constraints::NotBlank.new groups: "group1"
    @metadata.add_property_constraint "sub_object", AVD::Constraints::Valid.new groups: "group1"
    @sub_object_metadata.add_property_constraint "value", AVD::Constraints::NotBlank.new groups: "group1"

    self.validate(object, nil, ["default", "group1"]).size.should eq 2
  end

  def test_validate_sub_object_is_valided_in_multiple_groups_if_group_in_valid_constraint_is_validated : Nil
    object = Entity.new
    object.first_name = nil

    sub_object = SubEntity.new
    sub_object.value = nil

    object.sub_object = sub_object

    @metadata.add_property_constraint "first_name", AVD::Constraints::NotBlank.new
    @metadata.add_property_constraint "sub_object", AVD::Constraints::Valid.new groups: ["group1", "group2"]

    @sub_object_metadata.add_property_constraint "value", AVD::Constraints::NotBlank.new groups: "group1"
    @sub_object_metadata.add_property_constraint "value", AVD::Constraints::NotNil.new groups: "group2"

    self.validate(object, nil, ["default", "group1", "group2"]).size.should eq 3
  end
end
