require "./spec_helper"

private struct TestWriter < ART::Response::Writer
  def write(output : IO, & : IO -> Nil) : Nil
    yield output
    output.print "EOF"
  end
end

describe ART::Response do
  describe ".new" do
    it "defaults" do
      response = ART::Response.new
      response.headers.should be_empty
      response.content.should be_empty
      response.status.should eq HTTP::Status::OK
    end

    it "accepts an Int" do
      ART::Response.new(status: 201).status.should eq HTTP::Status::CREATED
    end

    it "accepts an HTTP::Status" do
      ART::Response.new(status: HTTP::Status::CREATED).status.should eq HTTP::Status::CREATED
    end

    it "accepts a string" do
      ART::Response.new("FOO").content.should eq "FOO"
    end

    it "accepts a block" do
      (ART::Response.new { |io| io << "BAZ" }).content.should eq "BAZ"
    end

    it "accepts a proc" do
      ART::Response.new(->(io : IO) { io << "BAR" }).content.should eq "BAR"
    end
  end

  describe "#content" do
    it "only executes the proc once" do
      value = 0
      response = ART::Response.new(->(io : IO) { io << "STRING"; value += 1 })
      response.content.should eq "STRING"
      value.should eq 1
      response.content.should eq "STRING"
      value.should eq 1
    end

    it "gets recalculated if the content changes" do
      value = 0
      response = ART::Response.new(->(io : IO) { io << "FOO"; value += 1 })
      response.content.should eq "FOO"
      value.should eq 1

      response.content = ->(io : IO) { io << "BAR"; value += 1 }
      response.content.should eq "BAR"
      value.should eq 2
    end
  end

  describe "#content=" do
    it "accepts a string" do
      response = ART::Response.new "FOO"
      response.content.should eq "FOO"
      response.content = "BAR"
      response.content.should eq "BAR"
    end
  end

  describe "#status=" do
    it "accepts an Int" do
      response = ART::Response.new
      response.status = 201
      response.status.should eq HTTP::Status::CREATED
    end

    it "accepts an HTTP::Status" do
      response = ART::Response.new
      response.status = HTTP::Status::CREATED
      response.status.should eq HTTP::Status::CREATED
    end
  end

  describe "#write" do
    it "writes the content to the given output IO" do
      io = IO::Memory.new
      ART::Response.new("FOO BAR").write io

      io.rewind.to_s.should eq "FOO BAR"
    end

    it "supports customization via an ART::Response::Writer" do
      io = IO::Memory.new
      response = ART::Response.new("FOO BAR")

      response.writer = TestWriter.new
      response.write io

      io.rewind.to_s.should eq "FOO BAREOF"
    end
  end
end
