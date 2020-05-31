require "./spec_helper"

struct DefaultConverter < Athena::Routing::ParamConverterInterface; end

struct TestConverter < Athena::Routing::ParamConverterInterface
  configuration value : Int32
end

describe ART::ParamConverterInterface do
  describe ART::ParamConverterInterface::ConfigurationInterface do
    describe ".configuration" do
      it "inherits the default configuration type if not used" do
        DefaultConverter::Configuration.should eq ART::ParamConverterInterface::Configuration
      end

      it "overrides the configuration type when used" do
        TestConverter::Configuration.should eq TestConverter::Configuration
      end

      it "creates a configuration struct with the provided arguments" do
        TestConverter::Configuration.new(value: 1, converter: TestConverter, name: "arg").value.should eq 1
      end
    end
  end
end
