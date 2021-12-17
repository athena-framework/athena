require "../spec_helper"

private record Entity do
  include AVD::Validatable
end

struct ClassMetadataTest < ASPEC::TestCase
  @metadata : AVD::Metadata::ClassMetadata(Entity)

  def initialize
    @metadata = AVD::Metadata::ClassMetadata(Entity).new
  end

  def test_add_constraint_array : Nil
    constraints = [CustomConstraint.new(""), CustomConstraint.new("")]

    @metadata.add_constraint constraints

    @metadata.constraints.should eq constraints

    constraints.each do |constraint|
      constraint.groups.should eq ["default", "Entity"]
    end
  end

  def test_add_property_constraints : Nil
    @metadata.add_property_constraints({
      "id"  => AVD::Constraints::NotBlank.new,
      "foo" => [CustomConstraint.new(""), AVD::Constraints::Valid.new],
    })

    @metadata.constrained_properties.should eq ["id", "foo"]
  end

  def test_add_property_constraint_name_and_array : Nil
    @metadata.add_property_constraint(
      "name",
      [CustomConstraint.new(""), CustomConstraint.new("")] of AVD::Constraint
    )

    @metadata.constrained_properties.should eq ["name"]
  end

  def test_add_property_constraint_name_and_single : Nil
    @metadata.add_property_constraint(
      "name",
      CustomConstraint.new ""
    )

    @metadata.constrained_properties.should eq ["name"]
  end

  def test_add_property_constraint_property_metadata_and_single : Nil
    @metadata.add_property_constraint(
      AVD::Metadata::PropertyMetadata(Entity, Nil).new("name"),
      CustomConstraint.new ""
    )

    @metadata.constrained_properties.should eq ["name"]
  end

  def test_add_constraint_single : Nil
    constraint = CustomConstraint.new ""

    @metadata.add_constraint constraint

    @metadata.constraints.should eq [constraint]
    constraint.groups.should eq ["default", "Entity"]
  end

  def test_group_sequence_default_group : Nil
    @metadata.group_sequence = ["Foo", @metadata.default_group]
    @metadata.group_sequence.should be_a AVD::Constraints::GroupSequence
  end

  def test_group_sequence_fails_if_missing_default_group : Nil
    expect_raises ArgumentError, "The group 'Entity' is missing from the group sequence." do
      @metadata.group_sequence = ["Foo", "Bar"]
    end
  end

  def test_group_sequence_fails_if_contains_default_group : Nil
    expect_raises ArgumentError, "The group 'default' is not allowed in group sequences." do
      @metadata.group_sequence = ["Foo", AVD::Constraint::DEFAULT_GROUP]
    end
  end

  def test_group_sequence_fails_if_is_provider : Nil
    metadata = AVD::Metadata::ClassMetadata(AVD::Spec::EntitySequenceProvider).new
    metadata.group_sequence_provider = true

    expect_raises ArgumentError, "Defining a static group sequence is not allowed with a group sequence provider." do
      metadata.group_sequence = ["Athena::Validator::Spec::EntitySequenceProvider", "Bar"]
    end
  end

  def test_group_sequence_provider_fails_if_is_provider : Nil
    metadata = AVD::Metadata::ClassMetadata(AVD::Spec::EntitySequenceProvider).new
    metadata.group_sequence = ["Athena::Validator::Spec::EntitySequenceProvider", "Bar"]

    expect_raises ArgumentError, "Defining a group sequence provider is not allowed with a static group sequence." do
      metadata.group_sequence_provider = true
    end
  end

  def test_has_property_metadata : Nil
    @metadata.add_property_constraint(
      AVD::Metadata::PropertyMetadata(Entity, Nil).new("name"),
      CustomConstraint.new ""
    )

    @metadata.has_property_metadata?("name").should be_true
    @metadata.has_property_metadata?("age").should be_false
  end

  def test_property_metadata : Nil
    name_metadata = AVD::Metadata::PropertyMetadata(Entity, Nil).new "name"

    @metadata.add_property_constraint name_metadata, CustomConstraint.new ""

    @metadata.property_metadata("name").should eq [name_metadata]
  end
end
