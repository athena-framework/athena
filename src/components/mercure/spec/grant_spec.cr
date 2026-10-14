require "./spec_helper"

describe AMC::Grant do
  describe ".from" do
    it "a list of grants" do
      grants = [AMC::Grant.new(:publish, ["a"]), AMC::Grant.new(:subscribe, {"urlpattern" => ["b"]})]

      AMC::Grant.from(grants).should eq grants
    end

    it "a topic" do
      AMC::Grant.from("a").should eq [AMC::Grant.new(:subscribe, ["a"])]
    end

    it "a list of topics" do
      AMC::Grant.from(["a", "b"]).should eq [AMC::Grant.new(:subscribe, ["a", "b"])]
    end

    it "a hash of topic matchers" do
      AMC::Grant.from({"urlpattern" => ["a"]}).should eq [AMC::Grant.new(:subscribe, {"urlpattern" => ["a"]})]
    end

    it "no topics" do
      AMC::Grant.from([] of String).should be_empty
      AMC::Grant.from({} of String => Array(String)).should be_empty
    end
  end

  describe "#topics_by_matcher" do
    it "a list of topics" do
      AMC::Grant.new(:subscribe, ["a"]).topics_by_matcher.should eq({"exact" => ["a"]})
    end

    it "a hash of topic matchers" do
      AMC::Grant.new(:subscribe, {"exact" => ["a"], "urlpattern" => ["b"]}).topics_by_matcher.should eq({"exact" => ["a"], "urlpattern" => ["b"]})
    end

    it "no topics" do
      AMC::Grant.new(:subscribe, [] of String).topics_by_matcher.should be_empty
    end
  end

  describe "#topics?" do
    it "with topics" do
      AMC::Grant.new(:subscribe, ["a"]).topics?.should be_true
      AMC::Grant.new(:subscribe, {"exact" => [] of String, "urlpattern" => ["b"]}).topics?.should be_true
    end

    it "without topics" do
      AMC::Grant.new(:subscribe, [] of String).topics?.should be_false
      AMC::Grant.new(:subscribe, {"urlpattern" => [] of String}).topics?.should be_false
    end
  end
end
