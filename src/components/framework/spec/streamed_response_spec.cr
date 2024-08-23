require "./spec_helper"

private struct TestWriter < ATH::Response::Writer
  def write(output : IO, & : IO -> Nil) : Nil
    yield output
    output.print "EOF"
  end
end

# FIXME: Refactor these specs to not depend on calling a protected method.
include ATHA

describe ATH::StreamedResponse do
  describe ".new" do
    it "accepts a block" do
      io = IO::Memory.new

      response = (ATH::StreamedResponse.new &.<<("BAZ"))

      response.write io

      io.to_s.should eq "BAZ"
    end

    it "accepts a proc" do
      io = IO::Memory.new
      proc = ->(i : IO) { i << "FOO" }

      response = ATH::StreamedResponse.new proc

      response.write io

      io.to_s.should eq "FOO"
    end

    it "accepts an Int status" do
      (ATH::StreamedResponse.new(status: 201, &.<<("BAZ"))).status.should eq HTTP::Status::CREATED
    end

    it "accepts an HTTP::Status status" do
      (ATH::StreamedResponse.new(status: :created, &.<<("BAZ"))).status.should eq HTTP::Status::CREATED
    end
  end

  describe "#content=" do
    it "raises on not nil content" do
      response = (ATH::StreamedResponse.new &.<<("BAZ"))

      expect_raises ATH::Exception::Logic, "The content cannot be set on a StreamedResponse instance." do
        response.content = "FOO"
      end
    end

    it "allows nil" do
      io = IO::Memory.new

      response = (ATH::StreamedResponse.new &.<<("BAZ"))

      response.content = nil

      response.write io

      io.to_s.should be_empty
    end
  end

  describe "#write" do
    it "supports customization via an ATH::Response::Writer" do
      io = IO::Memory.new
      response = (ATH::StreamedResponse.new &.<<("FOO BAR"))

      response.writer = TestWriter.new
      response.write io

      io.to_s.should eq "FOO BAREOF"
    end

    it "does not allow writing more than once" do
      io = IO::Memory.new
      response = (ATH::StreamedResponse.new &.<<("FOO BAR"))

      response.write io
      response.write io

      io.to_s.should eq "FOO BAR"
    end
  end
end
