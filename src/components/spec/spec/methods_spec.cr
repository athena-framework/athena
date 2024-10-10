require "./spec_helper"

describe ASPEC::Methods do
  describe ".assert_error", tags: "compiled" do
    it "allows customizing crystal binary via CRYSTAL env var" do
      begin
        ENV["CRYSTAL"] = "/path/to/crystal"

        expect_raises File::NotFoundError do
          assert_error "", ""
        end
      ensure
        ENV.delete "CRYSTAL"
      end
    end

    describe "no codegen" do
      it do
        assert_error "can't instantiate abstract class Foo", <<-CR
          abstract class Foo; end
          Foo.new
        CR
      end
    end

    describe "with codegen" do
      it do
        assert_error "Oh no", <<-CR, codegen: true
          raise "Oh no"
        CR
      end
    end
  end

  describe ".assert_success", tags: "compiled" do
    describe "no codegen" do
      it do
        assert_success <<-CR
          pp 1 + 1
        CR
      end

      it do
        assert_success <<-CR
          raise "Oh no"
        CR
      end
    end

    describe "with codegen" do
      it do
        assert_success <<-CR, codegen: true
          pp 1 + 1
        CR
      end
    end
  end

  describe ".run_executable", tags: "compiled" do
    it "without input" do
      run_executable "echo", ["foo", "bar"] do |output, error, status|
        output.should eq "foo bar\n"
        error.should be_empty
        status.success?.should be_true
      end
    end

    it "with input" do
      input = IO::Memory.new "foo\nbar"

      run_executable "cat", input, ["-e"] do |output, error, status|
        output.should eq "foo$\nbar"
        error.should be_empty
        status.success?.should be_true
      end
    end

    it "with error output" do
      run_executable "cat", args: ["missing.txt"] do |output, error, status|
        output.should be_empty
        error.should contain "No such file or directory"
        status.success?.should be_false
      end
    end
  end
end
