require "../spec_helper"

private struct IgnoreExclusionStrategy
  include ASR::ExclusionStrategies::ExclusionStrategyInterface

  # :inherit:
  def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
    false
  end
end

struct ContextTest < ASPEC::TestCase
  @context : ATH::View::Context

  def initialize
    @context = ATH::View::Context.new
  end

  def test_default_values : Nil
    @context.version.should be_nil
    @context.groups.should be_nil
    @context.emit_nil?.should be_nil
  end

  def test_adding_groups : Nil
    @context.add_groups "one", "two"
    @context.add_groups({"three"})
    @context.add_group "four"

    @context.groups.should eq Set{"one", "two", "three", "four"}
  end

  def test_set_groups : Nil
    @context.add_groups "foo", "bar"

    @context.groups.should eq Set{"foo", "bar"}

    @context.groups = {"one", "two"}

    @context.groups.should eq Set{"one", "two"}
  end

  def test_does_not_allow_duplicate_groups : Nil
    @context.add_group "one"
    @context.add_group "one"
    @context.add_group "two"

    @context.groups.should eq Set{"one", "two"}
  end

  def test_version : Nil
    @context.version = "1.2.3"

    @context.version.should eq SemanticVersion.new 1, 2, 3

    sem_ver = SemanticVersion.new 10, 9, 8

    @context.version = sem_ver

    @context.version.should eq sem_ver
  end

  def test_exclusion_strategies : Nil
    @context.exclusion_strategies.should be_empty

    strategy = IgnoreExclusionStrategy.new

    @context.add_exclusion_strategy strategy

    @context.exclusion_strategies.should eq [strategy]
  end
end
