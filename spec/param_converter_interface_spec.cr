require "./spec_helper"

struct DefaultConverter < Athena::Routing::ParamConverterInterface
  def apply(request : HTTP::Request, configuration : Configuration) : Nil; end
end

struct TestConverter < Athena::Routing::ParamConverterInterface
  configuration value : Int32

  def apply(request : HTTP::Request, configuration : Configuration) : Nil; end
end

struct DefaultValueConverter < Athena::Routing::ParamConverterInterface
  configuration enabled : Bool = false

  def apply(request : HTTP::Request, configuration : Configuration) : Nil; end
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

      it "allows default values" do
        DefaultValueConverter::Configuration.new(converter: DefaultValueConverter, name: "arg").enabled.should be_false
      end
    end
  end
end
