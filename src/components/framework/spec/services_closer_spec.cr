require "./spec_helper"

private class MockCloseable
  include ACTR::Service::Closeable

  getter? closed : Bool = false

  def close : Nil
    @closed = true
  end
end

@[ADI::Register]
class CountingCloseable
  include ACTR::Service::Closeable

  class_getter closed = 0

  def close : Nil
    @@closed += 1
  end
end

describe ATH::ServicesCloser do
  describe "#close" do
    it "closes each closeable" do
      closeables = [MockCloseable.new, MockCloseable.new]

      ATH::ServicesCloser.new(closeables.map &.as(ACTR::Service::Closeable)).close

      closeables.all?(&.closed?).should be_true
    end
  end
end

struct ServicesCloserTest < ATH::Spec::APITestCase
  def test_closes_closeable_services_once_the_request_is_done : Nil
    closed = CountingCloseable.closed

    self.get "/test"

    self.assert_response_is_successful
    CountingCloseable.closed.should eq closed + 1
  end
end
