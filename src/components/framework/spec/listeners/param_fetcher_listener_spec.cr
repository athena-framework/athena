require "../spec_helper"

private class MockParamFetcher
  include ATH::Params::ParamFetcherInterface

  def each(strict : Bool? = nil, &) : Nil
    yield "foo", "bar"
    yield "baz", "biz"
  end

  def get(name : String, strict : Bool? = nil)
    "default"
  end
end

describe ATH::Listeners::ParamFetcher do
  it "adds params into the requests attributes" do
    request = new_request

    event = ATH::Events::Action.new request, new_action

    ATH::Listeners::ParamFetcher.new(MockParamFetcher.new).on_action event

    request.attributes.get("foo").should eq "bar"
    request.attributes.get("baz").should eq "biz"
  end

  it "adds params into the requests attributes if the attribute already exists but is nil" do
    request = new_request
    request.attributes.set "foo", nil

    event = ATH::Events::Action.new request, new_action

    ATH::Listeners::ParamFetcher.new(MockParamFetcher.new).on_action event

    request.attributes.get("foo").should eq "bar"
    request.attributes.get("baz").should eq "biz"
  end

  it "errors if a attribute  params into the requests attributes if the attribute already exists but is nil" do
    request = new_request
    request.attributes.set "foo", "default"

    event = ATH::Events::Action.new request, new_action

    expect_raises ArgumentError, "Parameter 'foo' conflicts with a path parameter for route 'test_controller_test'." do
      ATH::Listeners::ParamFetcher.new(MockParamFetcher.new).on_action event
    end
  end
end
