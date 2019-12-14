require "./routing_spec_helper"

describe ART::ArgumentResolver do
  describe "without any parameters" do
    it "should return an empty array" do
      ART::ArgumentResolver.new.resolve(create).should be_empty
    end
  end

  describe "with a request paramter" do
    it "should return the current request" do
      request = create_request
      route = create_route(
        action: Proc(HTTP::Request, Int32).new { 1 },
        parameters: [ART::Parameters::RequestParameter(HTTP::Request).new "request"],
        argument_names: ["request"],
        type_vars: {Proc(Int32), Int32, HTTP::Request}
      )

      ctx = create(request: request, route: route)

      args = ART::ArgumentResolver.new.resolve(ctx)

      args.size.should eq 1
      args.first.should eq request
    end
  end
end
