require "./spec_helper"

struct MockParameter(T) < ART::Parameters::Parameter(T)
  def initialize(name : String, @value : String? = nil, default : T? = nil, type : T.class = T)
    super name, default, type
  end

  def extract(request : HTTP::Request) : String?
    @value
  end

  def parameter_type : String
    "mock"
  end
end

describe ART::ArgumentResolver do
  pending "with a request parameter" do
    it "should return the current request's path" do
      route = new_route parameters: [ART::Parameters::Request(HTTP::Request).new "request"] of ART::Parameters::Param
      request = new_request route: route

      ART::ArgumentResolver.new.resolve(request, route).should eq [request]
    end
  end

  describe :required do
    describe nil do
      it "should return a 400 if no default is given" do
        route = new_route parameters: [MockParameter(Int32).new "id"] of ART::Parameters::Param
        request = new_request route: route

        expect_raises ART::Exceptions::BadRequest, "Missing required mock parameter 'id'" do
          ART::ArgumentResolver.new.resolve request, route
        end
      end

      it "should use the default if a default is given" do
        route = new_route parameters: [MockParameter(Int32).new("id", default: 123)] of ART::Parameters::Param
        request = new_request route: route

        ART::ArgumentResolver.new.resolve(request, route).should eq [123]
      end
    end

    it "should return the value if it was able to be converted" do
      route = new_route parameters: [MockParameter(Int32).new "id", "19"] of ART::Parameters::Param
      request = new_request route: route

      ART::ArgumentResolver.new.resolve(request, route).should eq [19]
    end

    it "should raise a 422 if the value could not be converted" do
      route = new_route parameters: [MockParameter(Int32).new "id", "foo"] of ART::Parameters::Param
      request = new_request route: route

      expect_raises ART::Exceptions::UnprocessableEntity, "Required parameter 'id' with value 'foo' could not be converted into a valid 'Int32'" do
        ART::ArgumentResolver.new.resolve request, route
      end
    end
  end

  describe :optional do
    describe :not_provided do
      it "should return null if no default is given" do
        route = new_route parameters: [MockParameter(Int32?).new("id")] of ART::Parameters::Param
        request = new_request route: route

        ART::ArgumentResolver.new.resolve(request, route).should eq [nil]
      end

      it "should use the default if a default is given" do
        route = new_route parameters: [MockParameter(Int32?).new("id", default: 100)] of ART::Parameters::Param
        request = new_request route: route

        ART::ArgumentResolver.new.resolve(request, route).should eq [100]
      end
    end

    describe :provided do
      it "should return the value if provided" do
        route = new_route parameters: [MockParameter(Int32?).new("id", "123")] of ART::Parameters::Param
        request = new_request route: route

        ART::ArgumentResolver.new.resolve(request, route).should eq [123]
      end

      it "should return nil if not valid" do
        route = new_route parameters: [MockParameter(Int32?).new("id", "foo")] of ART::Parameters::Param
        request = new_request route: route

        ART::ArgumentResolver.new.resolve(request, route).should eq [nil]
      end
    end
  end
end
