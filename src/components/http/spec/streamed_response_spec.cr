require "./spec_helper"

private struct TestWriter < AHTTP::Response::Writer
  def write(output : IO, & : IO -> Nil) : Nil
    yield output
    output.print "EOF"
  end
end

describe AHTTP::StreamedResponse do
  describe ".new" do
    it "accepts a block" do
      io = IO::Memory.new

      response = (AHTTP::StreamedResponse.new &.<<("BAZ"))

      response.write io

      io.to_s.should eq "BAZ"
    end

    it "accepts a proc" do
      io = IO::Memory.new
      proc = ->(i : IO) { i << "FOO" }

      response = AHTTP::StreamedResponse.new proc

      response.write io

      io.to_s.should eq "FOO"
    end

    it "allows overriding the callback" do
      io = IO::Memory.new

      response = (AHTTP::StreamedResponse.new &.<<("BAZ"))
      response.content = ->(i : IO) { i << "BAR" }

      response.write io

      io.to_s.should eq "BAR"
    end

    it "accepts an Int status" do
      (AHTTP::StreamedResponse.new(status: 201, &.<<("BAZ"))).status.should eq ::HTTP::Status::CREATED
    end

    it "accepts an ::HTTP::Status status" do
      (AHTTP::StreamedResponse.new(status: :created, &.<<("BAZ"))).status.should eq ::HTTP::Status::CREATED
    end
  end

  describe "#content=" do
    it "raises on not nil content" do
      response = (AHTTP::StreamedResponse.new &.<<("BAZ"))

      expect_raises AHTTP::Exception::Logic, "The content cannot be set on a StreamedResponse instance." do
        response.content = "FOO"
      end
    end

    it "allows nil" do
      io = IO::Memory.new

      response = (AHTTP::StreamedResponse.new &.<<("BAZ"))

      response.content = nil

      response.write io

      io.to_s.should be_empty
    end
  end

  describe "#write" do
    it "supports customization via an AHTTP::Response::Writer" do
      io = IO::Memory.new
      response = (AHTTP::StreamedResponse.new &.<<("FOO BAR"))

      response.writer = TestWriter.new
      response.write io

      io.to_s.should eq "FOO BAREOF"
    end

    it "does not allow writing more than once" do
      io = IO::Memory.new
      response = (AHTTP::StreamedResponse.new &.<<("FOO BAR"))

      response.write io
      response.write io

      io.to_s.should eq "FOO BAR"
    end
  end
end
