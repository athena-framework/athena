require "../spec_helper"

describe ATH::Controller::ParameterMetadata do
  describe "#nilable?" do
    it "type is not nilable" do
      ATH::Controller::ParameterMetadata(Int32).new("foo").nilable?.should be_false
      ATH::Controller::ParameterMetadata(String | Bool).new("foo").nilable?.should be_false
    end

    it "type is nilable" do
      ATH::Controller::ParameterMetadata(Nil).new("foo").nilable?.should be_true
      ATH::Controller::ParameterMetadata(Int32?).new("foo").nilable?.should be_true
      ATH::Controller::ParameterMetadata(String | Bool | Nil).new("foo").nilable?.should be_true
    end
  end

  describe "#has_default?" do
    it true do
      ATH::Controller::ParameterMetadata(String).new("foo", true, "bar").has_default?.should be_true
    end

    it false do
      ATH::Controller::ParameterMetadata(Int32).new("foo", false, nil).has_default?.should be_false
    end
  end

  describe "#default_value" do
    it "with a default" do
      ATH::Controller::ParameterMetadata(String).new("foo", true, "bar").default_value.should eq "bar"
    end

    it "without a default" do
      expect_raises Exception, "Argument 'foo' does not have a default value." do
        ATH::Controller::ParameterMetadata(String).new("foo", false, nil).default_value
      end
    end
  end

  describe "#default_value?" do
    it "with a default" do
      ATH::Controller::ParameterMetadata(String).new("foo", true, "bar").default_value?.should eq "bar"
    end

    it "without a default" do
      ATH::Controller::ParameterMetadata(String).new("foo", false, nil).default_value?.should be_nil
    end
  end

  describe "#instance_of?" do
    it "with a scalar type" do
      ATH::Controller::ParameterMetadata(Int32).new("foo").instance_of?(Int32).should be_true
      ATH::Controller::ParameterMetadata(Int32).new("foo").instance_of?(Number).should be_true
      ATH::Controller::ParameterMetadata(Int32).new("foo").instance_of?(String).should be_false
    end

    it "with a union" do
      ATH::Controller::ParameterMetadata(String | Bool).new("foo").instance_of?(String).should be_true
      ATH::Controller::ParameterMetadata(Array(Bool) | Array(String)).new("foo").instance_of?(Array(String)).should be_true
    end

    it "nilable" do
      ATH::Controller::ParameterMetadata(String | Bool | Nil).new("foo").instance_of?(Bool).should be_true
      ATH::Controller::ParameterMetadata(String | Bool | Nil).new("foo").instance_of?(Int32).should be_false
      ATH::Controller::ParameterMetadata(Array(Bool) | Array(String) | Nil).new("foo").instance_of?(Array(String)).should be_true
      ATH::Controller::ParameterMetadata(Array(Bool) | Array(String) | Nil).new("foo").instance_of?(Array(Float64)).should be_false
    end
  end

  describe "#first_type_of" do
    it "with a single type var" do
      ATH::Controller::ParameterMetadata(Int32).new("foo").first_type_of(Int32).should eq Int32
      ATH::Controller::ParameterMetadata(Array(Int32)).new("foo").first_type_of(Array).should eq Array(Int32)
    end

    it "with a union" do
      ATH::Controller::ParameterMetadata(String | Int32 | Bool).new("foo").first_type_of(Int32).should eq Int32
      ATH::Controller::ParameterMetadata(Array(Int32) | Array(String)).new("foo").first_type_of(Array).should eq Array(Int32)
    end

    it "with a union of multiple valid type vars" do
      # Is Float64 because the union gets alphabetized
      ATH::Controller::ParameterMetadata(String | Int8 | Float64 | Int64).new("foo").first_type_of(Number).should eq Float64
    end

    it "with no matching type var" do
      ATH::Controller::ParameterMetadata(String | Int32 | Bool).new("foo").first_type_of(Array).should be_nil
      ATH::Controller::ParameterMetadata(String | Int32 | Bool).new("foo").first_type_of(Float64).should be_nil
    end
  end
end
