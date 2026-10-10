require "./spec_helper"

private class MockResettable
  include ACTR::Service::Resettable

  getter? reset_called : Bool = false

  def reset : Nil
    @reset_called = true
  end
end

describe ATH::ServicesResetter do
  describe "#reset" do
    it "resets each resettable" do
      resettables = [MockResettable.new, MockResettable.new]

      ATH::ServicesResetter.new(resettables.map &.as(ACTR::Service::Resettable)).reset

      resettables.all?(&.reset_called?).should be_true
    end
  end
end
