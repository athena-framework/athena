# :nodoc:
abstract struct Athena::Validator::Spec::AbstractValidatorTestCase < ASPEC::TestCase
  private class SubEntity
    include AVD::Validatable

    property value : String?
  end

  private abstract class Parent
    macro inherited
      include AVD::Validatable
    end
  end

  private class EntityParent < Parent
    property data : String = "data"
    property child : Entity? = nil
  end

  private class Entity < Parent
    property first_name : String?
    property! last_name : String
    property! sub_object : SubEntity
    property! sub_object2 : SubEntity
    property! hash_sub_object : Hash(String, SubEntity)
    property! nested_hash_sub_object : Hash(Int32, Hash(String, SubEntity))
    property! scalar_array : Array(Int32 | String)
    property! nil_array : Array(Nil)
    property! data_hash : Hash(String, String)
  end

  @metadata : AVD::Metadata::ClassMetadata(Entity)
  @sub_object_metadata : AVD::Metadata::ClassMetadata(SubEntity)
  @metadata_factory : AVD::Spec::MockMetadataFactory(EntityParent, Entity, SubEntity, EntitySequenceProvider, EntityGroupSequenceProvider)

  def initialize
    @metadata = AVD::Metadata::ClassMetadata(Entity).new
    @sub_object_metadata = AVD::Metadata::ClassMetadata(SubEntity).new
    @metadata_factory = AVD::Spec::MockMetadataFactory(EntityParent, Entity, SubEntity, EntitySequenceProvider, EntityGroupSequenceProvider).new
    @metadata_factory.add_metadata Entity, @metadata
    @metadata_factory.add_metadata SubEntity, @sub_object_metadata
  end

  abstract def validate(value, constraints, groups) : AVD::Violation::ConstraintViolationListInterface
  abstract def validate_property(object, property_name, groups) : AVD::Violation::ConstraintViolationListInterface
  abstract def validate_property_value(object, property_name, value, groups) : AVD::Violation::ConstraintViolationListInterface

  def test_validate : Nil
    callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      context.class_name.should be_nil
      context.property_name.should be_nil
      context.property_path.should be_empty
      context.group.should eq "group"
      context.root.should eq "Fred"
      context.value.should eq "Fred"
      value.should eq "Fred"

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    constraint = AVD::Constraints::Callback.new callback: callback, groups: ["group"]

    violations = self.validate "Fred", constraint, "group"

    violations.size.should eq 1

    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should be_empty
    violation.root.should eq "Fred"
    violation.invalid_value.should eq "Fred"
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_class_constraint : Nil
    object = Entity.new

    callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      context.class_name.should eq Entity
      context.property_name.should be_nil
      context.property_path.should be_empty
      context.group.should eq "group"
      context.root.should eq object
      context.value.should eq object
      value.should eq object

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group"]

    violations = self.validate object, groups: "group"

    violations.size.should eq 1

    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should be_empty
    violation.root.should eq object
    violation.invalid_value.should eq object
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_property_constraint : Nil
    object = Entity.new
    object.first_name = "Fred"

    callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      property_metadatas = @metadata.property_metadata "first_name"

      context.class_name.should eq Entity
      context.property_name.should eq "first_name"
      context.property_path.should eq "first_name"
      context.group.should eq "group"
      property_metadatas.first.should eq context.metadata
      context.root.should eq object
      context.value.should eq "Fred"
      value.should eq "Fred"

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    @metadata.add_property_constraint "first_name", AVD::Constraints::Callback.new callback: callback, groups: ["group"]

    violations = self.validate object, groups: "group"

    violations.size.should eq 1

    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should eq "first_name"
    violation.root.should eq object
    violation.invalid_value.should eq "Fred"
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_getter_constraint : Nil
    object = Entity.new
    object.first_name = "Fred"

    callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      property_metadatas = @metadata.property_metadata "first_name"

      context.class_name.should eq Entity
      context.property_name.should eq "first_name"
      context.property_path.should eq "first_name"
      context.group.should eq "group"
      property_metadatas.first.should eq context.metadata
      context.root.should eq object
      context.value.should eq "Fred"
      value.should eq "Fred"

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    @metadata.add_getter_constraint "first_name", AVD::Constraints::Callback.new callback: callback, groups: ["group"]

    violations = self.validate object, groups: "group"

    violations.size.should eq 1

    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should eq "first_name"
    violation.root.should eq object
    violation.invalid_value.should eq "Fred"
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_object_in_hash : Nil
    object = Entity.new
    hash = {"key" => object}

    callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      context.class_name.should eq Entity
      context.property_name.should be_nil
      context.property_path.should eq "[key]"
      context.group.should eq "group"
      context.metadata.should eq @metadata
      context.root.should eq hash
      context.value.should eq object
      value.should eq object

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group"]

    violations = self.validate hash, groups: "group"

    violations.size.should eq 1

    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should eq "[key]"
    violation.root.should eq hash
    violation.invalid_value.should eq object
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_object_in_nested_hash : Nil
    object = Entity.new
    hash = {2 => {"key" => object}}

    callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      context.class_name.should eq Entity
      context.property_name.should be_nil
      context.property_path.should eq "[2][key]"
      context.group.should eq "group"
      context.metadata.should eq @metadata
      context.root.should eq hash
      context.value.should eq object
      value.should eq object

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group"]

    violations = self.validate hash, groups: "group"

    violations.size.should eq 1

    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should eq "[2][key]"
    violation.root.should eq hash
    violation.invalid_value.should eq object
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_ignores_null_sub_objects : Nil
    object = Entity.new

    @metadata.add_property_constraint "sub_object", AVD::Constraints::Valid.new

    self.validate(object).should be_empty
  end

  def test_validate_only_traversal_cascaded_hash : Nil
    object = Entity.new
    object.hash_sub_object = {"key" => SubEntity.new}

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context, _payload|
      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    @metadata.add_property_constraint "hash_sub_object", AVD::Constraints::Callback.new callback: AVD::Constraints::Callback::CallbackProc.new { }, groups: ["group"]
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group"]

    self.validate(object, groups: "group").should be_empty
  end

  {% for method in ["add_property_constraint", "add_getter_constraint"] %}
    {% type = method.gsub(/add_/, "").id %}

    def test_validate_hash_sub_object_{{type}} : Nil
      object = Entity.new
      object.hash_sub_object = {"key" => SubEntity.new}

      callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
        context.class_name.should eq SubEntity
        context.property_name.should be_nil
        context.property_path.should eq "hash_sub_object[key]"
        context.group.should eq "group"
        context.metadata.should eq @sub_object_metadata
        context.root.should eq object
        context.value.should eq object.hash_sub_object["key"]
        value.should eq object.hash_sub_object["key"]

        context.add_violation "message \{{ value }}", {"\{{ value }}" => "value"}
      end

      @metadata.{{method.id}} "hash_sub_object", AVD::Constraints::Valid.new
      @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group"]

      violations = self.validate object, groups: "group"

      violations.size.should eq 1

      violation = violations.first

      violation.message.should eq "message value"
      violation.message_template.should eq "message \{{ value }}"
      violation.parameters.should eq({"\{{ value }}" => "value"})
      violation.property_path.should eq "hash_sub_object[key]"
      violation.root.should eq object
      violation.invalid_value.should eq object.hash_sub_object["key"]
      violation.plural.should be_nil
      violation.code.should be_nil
    end

    def test_validate_nested_hash_sub_object_{{type}} : Nil
      object = Entity.new
      object.nested_hash_sub_object = {2 => {"key" => SubEntity.new}}

      callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
        context.class_name.should eq SubEntity
        context.property_name.should be_nil
        context.property_path.should eq "nested_hash_sub_object[2][key]"
        context.group.should eq "group"
        context.metadata.should eq @sub_object_metadata
        context.root.should eq object
        context.value.should eq object.nested_hash_sub_object[2]["key"]
        value.should eq object.nested_hash_sub_object[2]["key"]

        context.add_violation "message \{{ value }}", {"\{{ value }}" => "value"}
      end

      @metadata.{{method.id}} "nested_hash_sub_object", AVD::Constraints::Valid.new
      @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group"]

      violations = self.validate object, groups: "group"

      violations.size.should eq 1

      violation = violations.first

      violation.message.should eq "message value"
      violation.message_template.should eq "message \{{ value }}"
      violation.parameters.should eq({"\{{ value }}" => "value"})
      violation.property_path.should eq "nested_hash_sub_object[2][key]"
      violation.root.should eq object
      violation.invalid_value.should eq object.nested_hash_sub_object[2]["key"]
      violation.plural.should be_nil
      violation.code.should be_nil
    end

    def test_validate_hash_traversal_cannot_be_disabled_{{type}} : Nil
      object = Entity.new
      object.hash_sub_object = {"key" => SubEntity.new}

      callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context, _payload|
        context.add_violation "message \{{ value }}", {"\{{ value }}" => "value"}
      end

      @metadata.{{method.id}} "hash_sub_object", AVD::Constraints::Valid.new traverse: false
      @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group"]

      self.validate(object, groups: "group").size.should eq 1
    end

    def test_validate_nested_hash_traversal_cannot_be_disabled_{{type}} : Nil
      object = Entity.new
      object.nested_hash_sub_object = {2 => {"key" => SubEntity.new}}

      callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context, _payload|
        context.add_violation "message \{{ value }}", {"\{{ value }}" => "value"}
      end

      @metadata.{{method.id}} "nested_hash_sub_object", AVD::Constraints::Valid.new traverse: false
      @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group"]

      self.validate(object, groups: "group").size.should eq 1
    end

    def test_validate_ignore_scalars_during_array_traversal_{{type}} : Nil
      object = Entity.new
      object.scalar_array = ["string", 1234]

      @metadata.{{method.id}} "scalar_array", AVD::Constraints::Valid.new

      self.validate(object, groups: "group").should be_empty
    end

    def test_validate_ignore_null_during_array_traversal_{{type}} : Nil
      object = Entity.new
      object.nil_array = [nil]

      @metadata.{{method.id}} "nil_array", AVD::Constraints::Valid.new

      self.validate(object, groups: "group").should be_empty
    end
  {% end %}

  def test_validate_property : Nil
    object = Entity.new
    object.first_name = "Jon"
    object.last_name = "Snow"

    callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      property_metadatas = @metadata.property_metadata "first_name"

      context.class_name.should eq Entity
      context.property_name.should eq "first_name"
      context.property_path.should eq "first_name"
      context.group.should eq "group"
      context.metadata.should eq property_metadatas.first
      context.root.should eq object
      context.value.should eq "Jon"
      value.should eq "Jon"

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |_value, context, _payload|
      context.add_violation "other violation"
    end

    @metadata.add_property_constraint "first_name", AVD::Constraints::Callback.new callback: callback, groups: ["group"]
    @metadata.add_property_constraint "last_name", AVD::Constraints::Callback.new callback: callback2, groups: ["group"]

    violations = self.validate_property object, "first_name", "group"

    violations.size.should eq 1
    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should eq "first_name"
    violation.root.should eq object
    violation.invalid_value.should eq "Jon"
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_property_no_constraints : Nil
    self.validate_property(Entity.new, "last_name").should be_empty
  end

  def test_validate_property_value : Nil
    object = Entity.new
    object.last_name = "Snow"

    callback = AVD::Constraints::Callback::CallbackProc.new do |value, context, _payload|
      property_metadatas = @metadata.property_metadata "first_name"

      context.class_name.should eq Entity
      context.property_name.should eq "first_name"
      context.property_path.should eq "first_name"
      context.group.should eq "group"
      context.metadata.should eq property_metadatas.first
      context.root.should eq object
      context.value.should eq "Jon"
      value.should eq "Jon"

      context.add_violation "message {{ value }}", {"{{ value }}" => "value"}
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |_value, context, _payload|
      context.add_violation "other violation"
    end

    @metadata.add_property_constraint "first_name", AVD::Constraints::Callback.new callback: callback, groups: ["group"]
    @metadata.add_property_constraint "last_name", AVD::Constraints::Callback.new callback: callback2, groups: ["group"]

    violations = self.validate_property_value object, "first_name", "Jon", "group"

    violations.size.should eq 1
    violation = violations.first

    violation.message.should eq "message value"
    violation.message_template.should eq "message {{ value }}"
    violation.parameters.should eq({"{{ value }}" => "value"})
    violation.property_path.should eq "first_name"
    violation.root.should eq object
    violation.invalid_value.should eq "Jon"
    violation.plural.should be_nil
    violation.code.should be_nil
  end

  def test_validate_property_value_no_constraints : Nil
    self.validate_property_value(Entity.new, "last_name", "foo").should be_empty
  end

  def ptest_validate_object_only_once_per_group : Nil
    object = Entity.new
    object.sub_object = object.sub_object2 = SubEntity.new

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message"
    end

    @metadata.add_property_constraint "sub_object", AVD::Constraints::Valid.new
    @metadata.add_property_constraint "sub_object2", AVD::Constraints::Valid.new
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback

    self.validate(object).size.should eq 1
  end

  def test_validate_different_objects_separately : Nil
    object = Entity.new
    object.sub_object = SubEntity.new
    object.sub_object2 = SubEntity.new

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message"
    end

    @metadata.add_property_constraint "sub_object", AVD::Constraints::Valid.new
    @metadata.add_property_constraint "sub_object2", AVD::Constraints::Valid.new
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback

    self.validate(object).size.should eq 2
  end

  def test_validate_single_group : Nil
    object = Entity.new

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message"
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group1"]
    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group2"]

    self.validate(object, groups: "group1").size.should eq 1
  end

  def test_validate_multiple_groups : Nil
    object = Entity.new

    callback = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "message"
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group1"]
    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback, groups: ["group2"]

    self.validate(object, groups: ["group1", "group2"]).size.should eq 2
  end

  def test_validate_replace_default_group_by_sequence_object : Nil
    object = Entity.new

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "group2 message"
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "group3 message"
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: AVD::Constraints::Callback::CallbackProc.new { }, groups: ["group1"]
    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: ["group2"]
    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: ["group3"]

    @metadata.group_sequence = AVD::Constraints::GroupSequence.new ["group1", "group2", "group3", "Athena::Validator::Spec::AbstractValidatorTestCase::Entity"]

    violations = self.validate object, groups: "default"

    violations.size.should eq 1
    violations.first.message.should eq "group2 message"
  end

  def test_validate_replace_default_group_by_array : Nil
    object = Entity.new

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "group2 message"
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "group3 message"
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: AVD::Constraints::Callback::CallbackProc.new { }, groups: ["group1"]
    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: ["group2"]
    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: ["group3"]

    @metadata.group_sequence = ["group1", "group2", "group3", "Athena::Validator::Spec::AbstractValidatorTestCase::Entity"]

    violations = self.validate object, groups: "default"

    violations.size.should eq 1
    violations.first.message.should eq "group2 message"
  end

  def test_validate_propagate_default_group_to_sub_object_when_replacing_default_group : Nil
    object = Entity.new
    object.sub_object = SubEntity.new

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "default group message"
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "group sequence message"
    end

    @metadata.add_property_constraint "sub_object", AVD::Constraints::Valid.new
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: ["default"]
    @sub_object_metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: ["group1"]

    @metadata.group_sequence = AVD::Constraints::GroupSequence.new ["group1", "Athena::Validator::Spec::AbstractValidatorTestCase::Entity"]

    violations = self.validate object, groups: "default"

    violations.size.should eq 1
    violations.first.message.should eq "default group message"
  end

  def test_validate_custom_group_when_default_group_was_replaced : Nil
    object = Entity.new
    object.sub_object = SubEntity.new

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "other group message"
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "group sequence message"
    end

    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: ["other group"]
    @metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: ["group1"]

    @metadata.group_sequence = AVD::Constraints::GroupSequence.new ["group1", "Athena::Validator::Spec::AbstractValidatorTestCase::Entity"]

    violations = self.validate object, groups: "other group"

    violations.size.should eq 1
    violations.first.message.should eq "other group message"
  end

  @[DataProvider("get_replace_default_group")]
  def test_replace_default_group(sequence : Array(String | Array(String)) | AVD::Constraints::GroupSequence, expected_violations : Array) : Nil
    object, metadata = case sequence
                       in Array
                         m = AVD::Metadata::ClassMetadata(EntitySequenceProvider).new
                         @metadata_factory.add_metadata EntitySequenceProvider, m
                         {EntitySequenceProvider.new(sequence), m}
                       in AVD::Constraints::GroupSequence
                         m = AVD::Metadata::ClassMetadata(EntityGroupSequenceProvider).new
                         @metadata_factory.add_metadata EntityGroupSequenceProvider, m
                         {EntityGroupSequenceProvider.new(sequence), m}
                       end

    callback1 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "violation in group2"
    end

    callback2 = AVD::Constraints::Callback::CallbackProc.new do |_value, context|
      context.add_violation "violation in group3"
    end

    metadata.add_constraint AVD::Constraints::Callback.new callback: AVD::Constraints::Callback::CallbackProc.new { }, groups: ["group1"]
    metadata.add_constraint AVD::Constraints::Callback.new callback: callback1, groups: ["group2"]
    metadata.add_constraint AVD::Constraints::Callback.new callback: callback2, groups: ["group3"]
    metadata.group_sequence_provider = true

    violations = self.validate object, groups: "default"

    violations.size.should eq expected_violations.size

    expected_violations.each_with_index do |message, idx|
      violations[idx].message.should eq message
    end
  end

  def get_replace_default_group : Tuple
    {
      {
        AVD::Constraints::GroupSequence.new(["group1", "group2", "group3", "Athena::Validator::Spec::AbstractValidatorTestCase::Entity"]),
        ["violation in group2"],
      },
      {
        ["group1", "group2", "group3", "Athena::Validator::Spec::AbstractValidatorTestCase::Entity"] of String | Array(String),
        ["violation in group2"],
      },
      {
        AVD::Constraints::GroupSequence.new(["group1", ["group2", "group3"], "Athena::Validator::Spec::AbstractValidatorTestCase::Entity"]),
        ["violation in group2", "violation in group3"],
      },
      {
        ["group1", ["group2", "group3"], "Athena::Validator::Spec::AbstractValidatorTestCase::Entity"],
        ["violation in group2", "violation in group3"],
      },
    }
  end
end
