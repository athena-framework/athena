require "./spec_helper"

private class MockCloseable
  include ATH::Closeable

  getter? closed : Bool = false

  def close : Nil
    @closed = true
  end
end

describe ATH::ServicesCloser do
  describe "#close" do
    it "closes each closeable" do
      closeables = [MockCloseable.new, MockCloseable.new]

      ATH::ServicesCloser.new(closeables.map &.as(ATH::Closeable)).close

      closeables.all?(&.closed?).should be_true
    end
  end
end
