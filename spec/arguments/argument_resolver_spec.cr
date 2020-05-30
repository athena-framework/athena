require "../spec_helper"

struct Athena::Routing::Arguments::ArgumentResolver
  getter argument_resolvers : Array(Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface)
end

private struct TrueResolver
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface

  # :inherit:
  def supports?(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata) : Bool
    true
  end

  # :inherit:
  def resolve(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata)
    17
  end
end

describe ART::Arguments::ArgumentResolver do
  describe "#get_arguments" do
    describe "when a value was able to be resolved" do
      it "should return an array of values" do
        route = new_route arguments: [new_argument]

        ART::Arguments::ArgumentResolver.new([TrueResolver.new] of ART::Arguments::Resolvers::ArgumentValueResolverInterface).get_arguments(new_request, route).should eq [17]
      end
    end

    describe "when a value was not able to be resolved" do
      it "should raise a runtime error" do
        route = new_route arguments: [new_argument]

        expect_raises(RuntimeError, "Could not resolve required argument 'id' for 'TestController#get_test'.") do
          ART::Arguments::ArgumentResolver.new([] of ART::Arguments::Resolvers::ArgumentValueResolverInterface).get_arguments(new_request, route)
        end
      end
    end
  end
end
