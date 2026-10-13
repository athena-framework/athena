require "../../spec_helper"

describe "Console bundle registered" do
  it "registers the debug commands" do
    application = ACON::Application.new "Athena", ATH::VERSION, ADI.container

    application.has?("debug:event-dispatcher").should be_true
    application.has?("debug:router").should be_true
    application.has?("debug:router:match").should be_true
  end
end
