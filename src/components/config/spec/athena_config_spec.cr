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

  describe Athena::Config do
    describe ".config" do
      it "should return an ACF::Base instance" do
        ACF.config.foo.should be_nil
      end

      it "should be a singleton" do
        ACF.config.should be ACF.config
      end
    end

    describe ".parameters" do
      it "should return an ACF::Parameters instance" do
        ACF.parameters.username.should eq "fred"
      end

      it "should be a singleton" do
        ACF.parameters.should be ACF.parameters
      end
    end
  end
end
