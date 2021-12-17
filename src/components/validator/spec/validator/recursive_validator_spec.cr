require "../spec_helper"

struct RecursiveValidatorTest < AVD::Spec::ValidatorTestCase
  def create_validator(metadata_factory : AVD::Metadata::MetadataFactoryInterface) : AVD::Validator::ValidatorInterface
    AVD::Validator::RecursiveValidator.new metadata_factory: metadata_factory
  end

  def test_validate_valid_constraint_on_getter_returning_null : Nil
    metadata = AVD::Metadata::ClassMetadata(EntityParent).new
    metadata.add_getter_constraint "child", AVD::Constraints::Valid.new

    @metadata_factory.add_metadata EntityParent, metadata

    self.validate(EntityParent.new).should be_empty
  end

  def test_validate_not_nil_constraint_on_getter_returning_null : Nil
    metadata = AVD::Metadata::ClassMetadata(EntityParent).new
    metadata.add_getter_constraint "child", AVD::Constraints::NotNil.new

    @metadata_factory.add_metadata EntityParent, metadata

    self.validate(EntityParent.new).size.should eq 1
  end

  def test_validate_all_constraint_validate_all_groups_for_nested_constraints : Nil
    @metadata.add_property_constraint "data_hash", AVD::Constraints::All.new([
      AVD::Constraints::NotBlank.new(groups: "group1"),
      AVD::Constraints::Size.new(2.., groups: "group2"),
    ])

    object = Entity.new
    object.data_hash = {"one" => "t", "two" => ""}

    violations = self.validate object, nil, ["group1", "group2"]

    violations.size.should eq 3

    violations[0].constraint.should be_a AVD::Constraints::NotBlank
    violations[1].constraint.should be_a AVD::Constraints::Size
    violations[2].constraint.should be_a AVD::Constraints::Size
  end
end
