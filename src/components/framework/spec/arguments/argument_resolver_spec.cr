require "../spec_helper"

struct Athena::Framework::Arguments::ArgumentResolver
  getter argument_resolvers : Array(Athena::Framework::Arguments::Resolvers::Interface)
end

private struct TrueResolver
  include Athena::Framework::Arguments::Resolvers::Interface

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Bool
    true
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    17
  end
end

describe ATH::Arguments::ArgumentResolver do
  describe "#get_arguments" do
    describe "when a value was able to be resolved" do
      it "should return an array of values" do
        route = new_action arguments: [new_argument]

        ATH::Arguments::ArgumentResolver.new([TrueResolver.new] of ATH::Arguments::Resolvers::Interface).get_arguments(new_request, route).should eq [17]
      end
    end

    describe "when a value was not able to be resolved" do
      it "should raise a runtime error" do
        route = new_action arguments: [new_argument]

        expect_raises(RuntimeError, "Could not resolve required argument 'id' for 'test_controller_test'.") do
          ATH::Arguments::ArgumentResolver.new([] of ATH::Arguments::Resolvers::Interface).get_arguments(new_request, route)
        end
      end
    end
  end
end
