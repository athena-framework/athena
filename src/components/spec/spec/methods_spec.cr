require "./spec_helper"
require "file_utils"

describe ASPEC::Methods do
  describe ".assert_compile_time_error", tags: "compiled" do
    it "allows customizing crystal binary via CRYSTAL env var" do
      # Do this in its own sub-process to avoid mucking with ENV.
      message = {% if flag? "windows" %}
                  "The system cannot find the file specified"
                {% else %}
                  "No such file or directory"
                {% end %}

      assert_runtime_error message, <<-CR
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

    describe "adjusts macro coverage line numbers for the stdin file", focus: true do
      it "without before/after code" do
        temp_dir = File.tempname
        Dir.mkdir_p(temp_dir)

        ENV["ATHENA_SPEC_COVERAGE_OUTPUT_DIR"] = temp_dir

        # We expect the line `{% x = 1 %}` to be called. Using __LINE__ and adding 3 keeps this robust if other tests are added/removed/re-arranged.
        spec_line = __LINE__ + 2
        code_line = __LINE__ + 3
        ASPEC::Methods.assert_compiles <<-'CR'
          macro finished
            {% x = 1 %}
          end
        CR

        coverage_file = Dir.glob(File.join(temp_dir, "macro_coverage.*.codecov.json")).first
        coverage_file.should end_with "macro_coverage.methods_spec:#{spec_line}.codecov.json"

        File.open coverage_file do |file|
          coverage = JSON.parse file

          # Should be 1 coverage file.
          coverages = coverage.as_h["coverage"].as_h
          coverages.size.should eq 1

          coverages.each_value do |file_coverage|
            # The expected line number should be called once
            file_coverage.as_h.should eq({code_line.to_s => 1})
          end
        end
      ensure
        ENV.delete("ATHENA_SPEC_COVERAGE_OUTPUT_DIR")
        FileUtils.rm_rf(temp_dir) if temp_dir
      end

      it "with code before" do
        temp_dir = File.tempname
        Dir.mkdir_p(temp_dir)

        ENV["ATHENA_SPEC_COVERAGE_OUTPUT_DIR"] = temp_dir

        # We expect the line `{% x = 1 %}` to be called. Using __LINE__ and adding 3 keeps this robust if other tests are added/removed/re-arranged.
        spec_line = __LINE__ + 2
        code_line = __LINE__ + 3
        ASPEC::Methods.assert_compiles <<-'CR', preamble: %(puts "hi")
          macro finished
            {% x = 1 %}
          end
        CR

        coverage_file = Dir.glob(File.join(temp_dir, "macro_coverage.*.codecov.json")).first
        coverage_file.should end_with "macro_coverage.methods_spec:#{spec_line}.codecov.json"

        File.open coverage_file do |file|
          coverage = JSON.parse file

          # Should be 1 coverage file.
          coverages = coverage.as_h["coverage"].as_h
          coverages.size.should eq 1

          coverages.each_value do |file_coverage|
            # The expected line number should be called once
            file_coverage.as_h.should eq({code_line.to_s => 1})
          end
        end
      ensure
        ENV.delete("ATHENA_SPEC_COVERAGE_OUTPUT_DIR")
        FileUtils.rm_rf(temp_dir) if temp_dir
      end
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
