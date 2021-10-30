require "./spec_helper"

private class DefaultConverter < Athena::Framework::ParamConverter
  def apply(request : ATH::Request, configuration : Configuration) : Nil; end
end

private class TestConverter < Athena::Framework::ParamConverter
  configuration value : Int32

  def apply(request : ATH::Request, configuration : Configuration) : Nil; end
end

private class DefaultValueConverter < Athena::Framework::ParamConverter
  configuration enabled : Bool = false

  def apply(request : ATH::Request, configuration : Configuration) : Nil; end
end

private class SingleGenericConverter < Athena::Framework::ParamConverter
  configuration type_vars: T

  def apply(request : ATH::Request, configuration : Configuration) : Nil; end
end

private class MultipleGenericConverter < Athena::Framework::ParamConverter
  configuration type_vars: {A, B}

  def apply(request : ATH::Request, configuration : Configuration) : Nil; end
end

describe ATH::ParamConverter do
  describe ATH::ParamConverter::ConfigurationInterface do
    describe ".configuration" do
      it "should automatically define a type specific configuration type if not used" do
        DefaultConverter::Configuration.should_not eq ATH::ParamConverter::Configuration
      end

      it "overrides the configuration type when used" do
        TestConverter::Configuration.should eq TestConverter::Configuration
        TestConverter::Configuration.should_not eq ATH::ParamConverter::Configuration
      end

      it "allows defining a single custom generic argument" do
        SingleGenericConverter::Configuration(Nil, Int32).should eq SingleGenericConverter::Configuration(Nil, Int32)
      end

      it "allows defining multiple custom generic arguments" do
        MultipleGenericConverter::Configuration(Nil, Int32, String).should eq MultipleGenericConverter::Configuration(Nil, Int32, String)
      end

      it "creates a configuration instance with the provided arguments" do
        TestConverter::Configuration(Nil).new(value: 1, converter: TestConverter, name: "arg").value.should eq 1
      end

      it "allows default values" do
        DefaultValueConverter::Configuration(Nil).new(converter: DefaultValueConverter, name: "arg").enabled.should be_false
      end
    end
  end
end
