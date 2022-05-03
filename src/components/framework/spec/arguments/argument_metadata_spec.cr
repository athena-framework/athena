require "../spec_helper"

describe ATH::Arguments::ArgumentMetadata do
  describe "#nilable?" do
    it "type is not nilable" do
      ATH::Arguments::ArgumentMetadata(Int32).new("foo").nilable?.should be_false
      ATH::Arguments::ArgumentMetadata(String | Bool).new("foo").nilable?.should be_false
    end

    it "type is nilable" do
      ATH::Arguments::ArgumentMetadata(Nil).new("foo").nilable?.should be_true
      ATH::Arguments::ArgumentMetadata(Int32?).new("foo").nilable?.should be_true
      ATH::Arguments::ArgumentMetadata(String | Bool | Nil).new("foo").nilable?.should be_true
    end
  end

  describe "#instance_of?" do
    it "with a scalar type" do
      ATH::Arguments::ArgumentMetadata(Int32).new("foo").instance_of?(Int32).should be_true
      ATH::Arguments::ArgumentMetadata(Int32).new("foo").instance_of?(Number).should be_true
      ATH::Arguments::ArgumentMetadata(Int32).new("foo").instance_of?(String).should be_false
    end

    it "with a union" do
      ATH::Arguments::ArgumentMetadata(String | Bool).new("foo").instance_of?(String).should be_true
      ATH::Arguments::ArgumentMetadata(Array(Bool) | Array(String)).new("foo").instance_of?(Array(String)).should be_true
    end

    it "nilable" do
      ATH::Arguments::ArgumentMetadata(String | Bool | Nil).new("foo").instance_of?(Bool).should be_true
      ATH::Arguments::ArgumentMetadata(String | Bool | Nil).new("foo").instance_of?(Int32).should be_false
      ATH::Arguments::ArgumentMetadata(Array(Bool) | Array(String) | Nil).new("foo").instance_of?(Array(String)).should be_true
      ATH::Arguments::ArgumentMetadata(Array(Bool) | Array(String) | Nil).new("foo").instance_of?(Array(Float64)).should be_false
    end
  end

  describe "#first_type_of" do
    it "with a single type var" do
      ATH::Arguments::ArgumentMetadata(Int32).new("foo").first_type_of(Int32).should eq Int32
      ATH::Arguments::ArgumentMetadata(Array(Int32)).new("foo").first_type_of(Array).should eq Array(Int32)
    end

    it "with a union" do
      ATH::Arguments::ArgumentMetadata(String | Int32 | Bool).new("foo").first_type_of(Int32).should eq Int32
      ATH::Arguments::ArgumentMetadata(Array(Int32) | Array(String)).new("foo").first_type_of(Array).should eq Array(Int32)
    end

    it "with a union of multiple valid type vars" do
      # Is Float64 because the union gets alphabetized
      ATH::Arguments::ArgumentMetadata(String | Int8 | Float64 | Int64).new("foo").first_type_of(Number).should eq Float64
    end

    it "with no matching type var" do
      ATH::Arguments::ArgumentMetadata(String | Int32 | Bool).new("foo").first_type_of(Array).should be_nil
      ATH::Arguments::ArgumentMetadata(String | Int32 | Bool).new("foo").first_type_of(Float64).should be_nil
    end
  end
end
