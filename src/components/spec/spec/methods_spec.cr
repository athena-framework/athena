require "./spec_helper"

describe ASPEC::Methods do
  describe ".assert_compile_time_error", tags: "compiled" do
    it "allows customizing crystal binary via CRYSTAL env var" do
      # Do this in its own sub-process to avoid mucking with ENV.
      assert_runtime_error "'/path/to/crystal': No such file or directory", <<-CR
        require "./spec_helper"

        ENV["CRYSTAL"] = "/path/to/crystal"

        assert_compile_time_error "", ""
      CR
    end

    it do
      assert_compile_time_error "can't instantiate abstract class Foo", <<-CR
          abstract class Foo; end
          Foo.new
        CR
    end
  end

  describe ".assert_runtime_error", tags: "compiled" do
    it do
      assert_runtime_error "Oh no", <<-CR
          raise "Oh no"
        CR
    end
  end

  describe ".assert_compiles", tags: "compiled" do
    it do
      assert_compiles <<-CR
          raise "Oh no"
        CR
    end
  end

  describe ".assert_executes", tags: "compiled" do
    it do
      assert_executes <<-CR
        puts 1 + 1
        CR
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
