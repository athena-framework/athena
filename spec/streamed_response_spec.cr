require "./spec_helper"

private struct TestWriter < ART::Response::Writer
  def write(output : IO, & : IO -> Nil) : Nil
    yield output
    output.print "EOF"
  end
end

describe ART::StreamedResponse, focus: true do
  describe ".new" do
    it "accepts a block" do
      io = IO::Memory.new

      response = (ART::StreamedResponse.new { |io| io << "BAZ" })

      response.write io

      io.to_s.should eq "BAZ"
    end

    it "accepts a proc" do
      io = IO::Memory.new
      proc = ->(io : IO) { io << "FOO" }

      response = ART::StreamedResponse.new proc

      response.write io

      io.to_s.should eq "FOO"
    end

    it "accepts an Int status" do
      (ART::StreamedResponse.new(status: 201) { |io| io << "BAZ" }).status.should eq HTTP::Status::CREATED
    end

    it "accepts an HTTP::Status status" do
      (ART::StreamedResponse.new(status: :created) { |io| io << "BAZ" }).status.should eq HTTP::Status::CREATED
    end
  end

  describe "#content=" do
    it "raises on not nil content" do
      response = (ART::StreamedResponse.new { |io| io << "BAZ" })

      expect_raises Exception, "The content cannot be set on a StreamedResponse instance." do
        response.content = "FOO"
      end
    end

    it "allows nil" do
      io = IO::Memory.new

      response = (ART::StreamedResponse.new { |io| io << "BAZ" })

      response.content = nil

      response.write io

      io.to_s.should be_empty
    end
  end

  describe "#write" do
    it "supports customization via an ART::Response::Writer" do
      io = IO::Memory.new
      response = (ART::StreamedResponse.new { |io| io << "FOO BAR" })

      response.writer = TestWriter.new
      response.write io

      io.to_s.should eq "FOO BAREOF"
    end

    it "does not allow writing more than once" do
      io = IO::Memory.new
      response = (ART::StreamedResponse.new { |io| io << "FOO BAR" })

      response.write io
      response.write io

      io.to_s.should eq "FOO BAR"
    end
  end
end
