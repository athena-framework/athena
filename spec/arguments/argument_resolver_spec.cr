require "../spec_helper"

struct Athena::Routing::Arguments::ArgumentResolver
  getter resolvers : Array(Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface)
end

struct TrueResolver
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface

  # :inherit:
  def self.priority : Int32
    0
  end

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
  describe "#initialize" do
    it "sorts the resolvers on init" do
      resolver = ART::Arguments::ArgumentResolver.new [ART::Arguments::Resolvers::DefaultValue.new, ART::Arguments::Resolvers::Request.new] of ART::Arguments::Resolvers::ArgumentValueResolverInterface

      resolvers = resolver.resolvers
      resolvers[0].should be_a ART::Arguments::Resolvers::Request
      resolvers[1].should be_a ART::Arguments::Resolvers::DefaultValue
    end
  end

  # Pending until https://github.com/crystal-lang/crystal/issues/8812 is fixed.
  describe "#get_arguments" do
    describe "when a value was able to be resolved" do
      it "should return an array of values" do
        route = new_route arguments: [new_argument]

        ART::Arguments::ArgumentResolver.new([TrueResolver.new] of ART::Arguments::Resolvers::ArgumentValueResolverInterface).get_arguments(new_request, route).should eq [17]
      end
    end

    describe "when a value was not able to be resolved" do
      it "should raise a bad request exception" do
        route = new_route arguments: [new_argument]

        expect_raises(ART::Exceptions::BadRequest, "Missing required parameter 'id'") do
          ART::Arguments::ArgumentResolver.new([] of ART::Arguments::Resolvers::ArgumentValueResolverInterface).get_arguments(new_request, route)
        end
      end
    end
  end
end
