require "./spec_helper"

describe Athena::Validator, tags: "compiled" do
  describe "without the optional components" do
    it "compiles the File and Image validators" do
      ASPEC::Methods.assert_compiles <<-'CR'
        require "../src/athena-validator"

        AVD.validator.validate "foo.gif", AVD::Constraints::Image.new(min_width: 1)
      CR
    end

    it "validates files" do
      ASPEC::Methods.assert_executes <<-'CR'
        require "spec"
        require "../src/athena-validator"

        it "does not require the optional components" do
          {{ %w(AHTTP AIS AMIME).any? { |name| @top_level.has_constant? name } }}.should be_false
        end

        it "validates files" do
          path = "#{__DIR__}/constraints/fixtures/file-big.txt"

          AVD.validator.validate(path, AVD::Constraints::File.new).size.should eq 0
          AVD.validator.validate(path, AVD::Constraints::File.new(max_size: 1)).size.should eq 1
        end
      CR
    end

    it "requires the MIME component to validate MIME types" do
      ASPEC::Methods.assert_runtime_error "You cannot validate the MIME type of files as the MIME component is not installed.", <<-'CR'
        require "../src/athena-validator"

        AVD.validator.validate "#{__DIR__}/constraints/fixtures/file-big.txt", AVD::Constraints::File.new(mime_types: {"text/plain"})
      CR
    end

    it "requires the ImageSize component to validate image dimensions" do
      ASPEC::Methods.assert_runtime_error "You cannot validate the dimensions of images as the ImageSize component is not installed.", <<-'CR'
        require "../src/athena-validator"
        require "athena-mime"

        AVD.validator.validate "#{__DIR__}/constraints/fixtures/2x2.gif", AVD::Constraints::Image.new(min_width: 1)
      CR
    end
  end
end
