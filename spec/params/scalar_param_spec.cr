require "../spec_helper"

private struct MockScalarParam(T) < ART::Params::ScalarParam
  define_initializer

  def extract_value(request : HTTP::Request, default = nil) : Nil
  end
end

describe ART::Params::ScalarParam do
  describe "#constraints" do
    describe "not nilable, no requirements, no map" do
      it "inherits the NotNil constraint from its parent" do
        constraints = MockScalarParam(Int32).new("id", has_default: false, is_nilable: false).constraints
        constraints.size.should eq 1
        constraints[0].should be_a AVD::Constraints::NotNil
      end
    end

    describe "mapped" do
      it "it wraps the constraint in an All constraint and NotNil" do
        constraints = MockScalarParam(Int32).new("id", has_default: false, is_nilable: false, map: true).constraints

        constraints.size.should eq 2
        constraint = constraints[0].should be_a AVD::Constraints::All
        constraints[1].should be_a AVD::Constraints::NotNil

        constraint.constraints.size.should eq 1
        constraint.constraints[0].should be_a AVD::Constraints::NotNil
      end

      it "it wraps the constraint in an All constraint and not NotNil" do
        constraints = MockScalarParam(Int32).new("id", has_default: false, is_nilable: true, map: true).constraints

        constraints.size.should eq 1
        constraint = constraints[0].should be_a AVD::Constraints::All

        constraint.constraints.should be_empty
      end
    end

    describe "with requirements" do
      it Regex do
        constraints = MockScalarParam(Int32).new("id", has_default: false, is_nilable: true, requirements: /\d+/).constraints
        constraints.size.should eq 1
        constraint = constraints[0].should be_a AVD::Constraints::Regex

        constraint.pattern.should eq /^(?-imsx:\d+)$/
      end

      it AVD::Constraint do
        constraints = MockScalarParam(Int32).new("id", has_default: false, is_nilable: true, requirements: AVD::Constraints::NotBlank.new).constraints
        constraints.size.should eq 1
        constraints[0].should be_a AVD::Constraints::NotBlank
      end

      it Array(AVD::Constraint) do
        constraints = MockScalarParam(Int32).new("id", has_default: false, is_nilable: false, requirements: [AVD::Constraints::NotBlank.new, AVD::Constraints::Positive.new]).constraints
        constraints.size.should eq 3
        constraints[0].should be_a AVD::Constraints::NotNil
        constraints[1].should be_a AVD::Constraints::NotBlank
        constraints[2].should be_a AVD::Constraints::Positive
      end
    end
  end
end
