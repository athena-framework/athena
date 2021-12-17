require "../spec_helper"

describe ASR::ExclusionStrategies::Groups do
  describe "#skip_property?" do
    describe "that is in the default group" do
      it "should not skip" do
        assert_groups(groups: ["default"]).should be_false
      end
    end

    describe "that includes at least one group" do
      it "should not skip" do
        assert_groups(groups: ["one", "two"], metadata_groups: ["two", "three"]).should be_false
      end
    end

    describe "that does not include any group" do
      it "should skip" do
        assert_groups(groups: ["one", "two"], metadata_groups: ["three", "four"]).should be_true
      end
    end

    it "splat argument" do
      ASR::ExclusionStrategies::Groups.new("one", "two", "three").skip_property?(create_metadata(groups: ["default"]), ASR::SerializationContext.new).should be_true
      ASR::ExclusionStrategies::Groups.new("one", "default", "three").skip_property?(create_metadata(groups: ["default"]), ASR::SerializationContext.new).should be_false
    end
  end
end
