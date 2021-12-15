require "../spec_helper"

describe ASR::ExclusionStrategies::Version do
  describe "#skip_property?" do
    describe :since_version do
      describe "that isnt set" do
        it "should not skip" do
          assert_version.should be_false
        end
      end

      describe "that is less than the version" do
        it "should not skip" do
          assert_version(since_version: "0.31.0").should be_false
        end
      end

      describe "that is equal than the version" do
        it "should not skip" do
          assert_version(since_version: "1.0.0").should be_false
        end
      end

      describe "that is larger than the version" do
        it "should skip" do
          assert_version(since_version: "1.5.0").should be_true
        end
      end
    end

    describe :until_version do
      describe "that isnt set" do
        it "should not skip" do
          assert_version.should be_false
        end
      end

      describe "that is less than the version" do
        it "should skip" do
          assert_version(until_version: "0.31.0").should be_true
        end
      end

      describe "that is equal than the version" do
        it "should skip" do
          assert_version(until_version: "1.0.0").should be_true
        end
      end

      describe "that is larger than the version" do
        it "should not skip" do
          assert_version(until_version: "1.5.0").should be_false
        end
      end
    end
  end
end
