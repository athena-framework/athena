require "./spec_helper"

private struct DefaultConverter < Athena::Routing::ParamConverterInterface
  def apply(request : ART::Request, configuration : Configuration) : Nil; end
end

private struct TestConverter < Athena::Routing::ParamConverterInterface
  configuration value : Int32

  def apply(request : ART::Request, configuration : Configuration) : Nil; end
end

private struct DefaultValueConverter < Athena::Routing::ParamConverterInterface
  configuration enabled : Bool = false

  def apply(request : ART::Request, configuration : Configuration) : Nil; end
end

private struct SingleGenericConverter < Athena::Routing::ParamConverterInterface
  configuration type_vars: T

  def apply(request : ART::Request, configuration : Configuration) : Nil; end
end

private struct MultipleGenericConverter < Athena::Routing::ParamConverterInterface
  configuration type_vars: {A, B}

  def apply(request : ART::Request, configuration : Configuration) : Nil; end
end

describe ART::ParamConverterInterface do
  describe ART::ParamConverterInterface::ConfigurationInterface do
    describe ".configuration" do
      it "should automatically define a type specific configuration type if not used" do
        DefaultConverter::Configuration.should_not eq ART::ParamConverterInterface::Configuration
      end

      it "overrides the configuration type when used" do
        TestConverter::Configuration.should eq TestConverter::Configuration
        TestConverter::Configuration.should_not eq ART::ParamConverterInterface::Configuration
      end

      it "allows defining a single custom generic argument" do
        SingleGenericConverter::Configuration(Nil, Int32).should eq SingleGenericConverter::Configuration(Nil, Int32)
      end

      it "allows defining multiple custom generic arguments" do
        MultipleGenericConverter::Configuration(Nil, Int32, String).should eq MultipleGenericConverter::Configuration(Nil, Int32, String)
      end

      it "creates a configuration struct with the provided arguments" do
        TestConverter::Configuration(Nil).new(value: 1, converter: TestConverter, name: "arg").value.should eq 1
      end

      it "allows default values" do
        DefaultValueConverter::Configuration(Nil).new(converter: DefaultValueConverter, name: "arg").enabled.should be_false
      end
    end
  end
end
