require "./spec_helper"

describe Athena::HTTP, tags: "compiled" do
  describe "without the optional components" do
    it "compiles the session storage" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../src/athena-http"

        AHTTP::Session::Storage::Factory.new(AHTTP::Session::Storage::Handler::Memory.new).create_storage(nil).start
      CR
    end

    it "uses the system time for the session metadata" do
      ASPEC::Methods.assert_executes <<-'CR'
        require "spec"
        require "../src/athena-http"

        it "does not require the optional components" do
          {{ @top_level.has_constant? "ACLK" }}.should be_false
        end

        it "uses the system time for the session metadata" do
          factory = AHTTP::Session::Storage::Factory.new AHTTP::Session::Storage::Handler::Memory.new
          storage = factory.create_storage nil
          storage.start

          storage.metadata_bag.created.should be_close Time.utc, 5.seconds
        end
      CR
    end
  end
end
