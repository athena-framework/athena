require "../spec_helper"

private class MockParamFetcher
  include ART::Params::ParamFetcherInterface

  def each(strict : Bool? = nil, &) : Nil
    yield "foo", "bar"
    yield "baz", "biz"
  end

  def get(name : String, strict : Bool? = nil)
    "default"
  end
end

describe ART::Listeners::ParamFetcher do
  it "adds params into the requests attributes" do
    request = new_request

    event = ART::Events::Action.new request, new_action

    ART::Listeners::ParamFetcher.new(MockParamFetcher.new).call(event, AED::Spec::TracableEventDispatcher.new)

    request.attributes.get("foo").should eq "bar"
    request.attributes.get("baz").should eq "biz"
  end

  it "adds params into the requests attributes if the attribute already exists but is nil" do
    request = new_request
    request.attributes.set "foo", nil

    event = ART::Events::Action.new request, new_action

    ART::Listeners::ParamFetcher.new(MockParamFetcher.new).call(event, AED::Spec::TracableEventDispatcher.new)

    request.attributes.get("foo").should eq "bar"
    request.attributes.get("baz").should eq "biz"
  end

  it "errors if a attribute  params into the requests attributes if the attribute already exists but is nil" do
    request = new_request
    request.attributes.set "foo", "default"

    event = ART::Events::Action.new request, new_action

    expect_raises ArgumentError, "Parameter 'foo' conflicts with a path parameter for route 'test'." do
      ART::Listeners::ParamFetcher.new(MockParamFetcher.new).call(event, AED::Spec::TracableEventDispatcher.new)
    end
  end
end
