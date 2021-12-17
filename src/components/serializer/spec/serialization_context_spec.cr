require "./spec_helper"

struct False
  include ASR::ExclusionStrategies::ExclusionStrategyInterface

  # :inherit:
  def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
    false
  end
end

describe ASR::SerializationContext do
  describe "#init" do
    it "that wasn't already inited" do
      context = ASR::SerializationContext.new
      context.groups = {"group1"}
      context.version = "1.0.0"

      context.exclusion_strategy.should be_nil

      context.init

      context.exclusion_strategy.should be_a ASR::ExclusionStrategies::Disjunct
      context.exclusion_strategy.try &.as(ASR::ExclusionStrategies::Disjunct).members.size.should eq 2
    end

    it "that was already inited" do
      context = ASR::SerializationContext.new

      context.init

      expect_raises ASR::Exceptions::SerializerException, "This context was already initialized, and cannot be re-used." do
        context.init
      end
    end
  end

  describe "#add_exclusion_strategy" do
    describe "with no previous strategy" do
      it "should set it directly" do
        context = ASR::SerializationContext.new
        context.exclusion_strategy.should be_nil

        context.add_exclusion_strategy False.new

        context.exclusion_strategy.should be_a False
      end
    end

    describe "with a strategy already set" do
      it "should use a Disjunct strategy" do
        context = ASR::SerializationContext.new
        context.exclusion_strategy.should be_nil

        context.add_exclusion_strategy False.new
        context.add_exclusion_strategy False.new

        context.exclusion_strategy.should be_a ASR::ExclusionStrategies::Disjunct
        context.exclusion_strategy.try &.as(ASR::ExclusionStrategies::Disjunct).members.size.should eq 2
      end
    end

    describe "with a multiple strategies already set" do
      it "should push the member to the Disjunct strategy" do
        context = ASR::SerializationContext.new
        context.exclusion_strategy.should be_nil

        context.add_exclusion_strategy False.new
        context.add_exclusion_strategy False.new
        context.add_exclusion_strategy False.new

        context.exclusion_strategy.should be_a ASR::ExclusionStrategies::Disjunct
        context.exclusion_strategy.try &.as(ASR::ExclusionStrategies::Disjunct).members.size.should eq 3
      end
    end
  end

  describe "#groups=" do
    it "sets the groups" do
      context = ASR::SerializationContext.new.groups = ["one", "two"]
      context.groups.should eq Set{"one", "two"}
    end

    it "raises if the groups are empty" do
      expect_raises ArgumentError, "Groups cannot be empty" do
        ASR::SerializationContext.new.groups = [] of String
      end
    end
  end

  describe "#version=" do
    it "sets the version as a `SemanticVersion`" do
      context = ASR::SerializationContext.new.version = "1.1.1"
      context.version.should eq SemanticVersion.new 1, 1, 1
    end
  end
end
