require "./spec_helper"

describe Athena do
  describe ".environment" do
    before_each do
      ENV.delete Athena::ENV_NAME
    end

    it "should use the default env if an ENV var is not defined" do
      ENV.has_key?(Athena::ENV_NAME).should be_false
      Athena.environment.should eq "development"
    end

    it "should use ENV var path if defined" do
      ENV[Athena::ENV_NAME] = "production"
      Athena.environment.should eq "production"
    end
  end
end
