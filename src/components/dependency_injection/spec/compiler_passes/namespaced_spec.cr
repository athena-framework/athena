require "../spec_helper"

@[ADI::Register(public: true)]
class MyApp::Models::Foo
end

@[ADI::Register(public: true)]
class NamespaceClient
  getter service

  def initialize(@service : MyApp::Models::Foo); end
end

describe ADI::ServiceContainer do
  it "correctly resolves the service" do
    ADI.container.namespace_client.service.should be_a MyApp::Models::Foo
  end
end
