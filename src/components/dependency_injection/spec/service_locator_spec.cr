require "./spec_helper"

private def new_locator(factories : Hash(String, Proc(String)) = {"first" => -> { "first service" }, "second" => -> { "second service" }}) : ADI::ServiceLocator(String)
  ADI::ServiceLocator(String).new factories
end

describe ADI::ServiceLocator do
  describe "#get" do
    it "returns the service" do
      new_locator.get("second").should eq "second service"
    end

    it "only calls the factory of the requested service" do
      calls = [] of String
      locator = new_locator({"first" => -> { calls << "first"; "first service" }, "second" => -> { calls << "second"; "second service" }})

      locator.get "second"

      calls.should eq ["second"]
    end

    it "raises if there are no services" do
      expect_raises KeyError, "Service 'missing' not found: the current service locator is empty." do
        new_locator({} of String => Proc(String)).get "missing"
      end
    end

    it "raises if there is another service" do
      expect_raises KeyError, "Service 'missing' not found: the current service locator only knows about the 'first' service." do
        new_locator({"first" => -> { "first service" }}).get "missing"
      end
    end

    it "raises if there are other services" do
      expect_raises KeyError, "Service 'missing' not found: the current service locator only knows about the 'first', 'second' and 'third' services." do
        new_locator({"first" => -> { "first service" }, "second" => -> { "second service" }, "third" => -> { "third service" }}).get "missing"
      end
    end
  end

  describe "#get?" do
    it "returns the service" do
      new_locator.get?("first").should eq "first service"
    end

    it "returns nil if the service is not provided" do
      new_locator.get?("missing").should be_nil
    end
  end

  describe "#has?" do
    it "returns whether the service is provided" do
      new_locator.has?("first").should be_true
      new_locator.has?("missing").should be_false
    end
  end

  describe "#provided_services" do
    it "returns the IDs of the provided services" do
      new_locator.provided_services.should eq ["first", "second"]
    end
  end
end
