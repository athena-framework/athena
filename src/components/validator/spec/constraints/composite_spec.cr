private class ConcreteComposite < AVD::Constraints::Composite
  def initialize(
    constraints : Array(AVD::Constraint) | AVD::Constraint = [] of AVD::Constraint,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super constraints, "", groups, payload
  end

  # :inherit:
  def validated_by : NoReturn
    raise "BUG: #{self} cannot be validated"
  end
end

struct CompositeTest < ASPEC::TestCase
  def test_default_group : Nil
    constraint = ConcreteComposite.new([
      AVD::Constraints::NotNil.new,
      AVD::Constraints::NotBlank.new,
    ])

    constraint.groups.should eq ["default"]
    constraint.constraints[0].groups.should eq ["default"]
    constraint.constraints[1].groups.should eq ["default"]
  end

  def test_nested_composite_constraint_has_default_group : Nil
    constraint = ConcreteComposite.new([
      ConcreteComposite.new,
      ConcreteComposite.new,
    ] of AVD::Constraint)

    constraint.groups.should eq ["default"]
    constraint.constraints[0].groups.should eq ["default"]
    constraint.constraints[1].groups.should eq ["default"]
  end

  def test_implicit_nested_groups_if_explicit_parent_group : Nil
    constraint = ConcreteComposite.new([
      AVD::Constraints::NotNil.new,
      AVD::Constraints::NotBlank.new,
    ], groups: ["default", "strict"])

    constraint.groups.should eq ["default", "strict"]
    constraint.constraints[0].groups.should eq ["default", "strict"]
    constraint.constraints[1].groups.should eq ["default", "strict"]
  end

  def test_explicit_nested_groups_must_be_subset_of_explicit_parent_groups : Nil
    constraint = ConcreteComposite.new([
      AVD::Constraints::NotNil.new(groups: "default"),
      AVD::Constraints::NotBlank.new(groups: "strict"),
    ], groups: ["default", "strict"])

    constraint.groups.should eq ["default", "strict"]
    constraint.constraints[0].groups.should eq ["default"]
    constraint.constraints[1].groups.should eq ["strict"]
  end

  def test_fail_if_explicit_nest_group_not_subset_of_explicit_parent_groups : Nil
    expect_raises AVD::Exception::Logic, "The group(s) 'foobar' passed to the constraint 'Athena::Validator::Constraints::NotNil' should also be passed to its containing constraint 'ConcreteComposite'." do
      ConcreteComposite.new([
        AVD::Constraints::NotNil.new(groups: ["default", "foobar"]),
      ] of AVD::Constraint, groups: ["default", "strict"])
    end
  end

  def test_implicit_group_names_are_forwarded : Nil
    constraint = ConcreteComposite.new([
      AVD::Constraints::NotNil.new(groups: "default"),
      AVD::Constraints::NotBlank.new(groups: "strict"),
    ])

    constraint.add_implicit_group "implicit"

    constraint.groups.should eq ["default", "strict", "implicit"]
    constraint.constraints[0].groups.should eq ["default", "implicit"]
    constraint.constraints[1].groups.should eq ["strict"]
  end

  def test_valid_cannot_be_nested : Nil
    expect_raises AVD::Exception::Logic, "The 'Athena::Validator::Constraints::Valid' constraint cannot be nested inside a 'ConcreteComposite' constraint." do
      ConcreteComposite.new([
        AVD::Constraints::Valid.new,
      ] of AVD::Constraint)
    end
  end

  def test_single_element_inferred_type_array : Nil
    constraint = ConcreteComposite.new([
      AVD::Constraints::Positive.new,
    ])

    constraint.constraints.size.should eq 1
    constraint.groups.should eq ["default"]
  end
end
