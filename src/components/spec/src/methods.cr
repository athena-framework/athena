# Namespace for common/helpful testing methods.
#
# This module can be included into your `spec_helper` in order
# to allow your specs to use them all.  This module is also
# included into `ASPEC::TestCase` by default to allow using them
# within your unit tests as well.
#
# May be reopened to add additional application specific helpers.
module Athena::Spec::Methods
  extend self

  # Executes the provided Crystal *code* and asserts it results in a compile time error with the provided *message*.
  #
  # ```
  # ASPEC::Methods.assert_compile_time_error "can't instantiate abstract class Foo", <<-CR
  #   abstract class Foo; end
  #   Foo.new
  # CR
  # ```
  #
  # NOTE: When files are required within the *code*, they are relative to the file calling this method.
  def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__, file : String = __FILE__) : Nil
    std_out = IO::Memory.new
    std_err = IO::Memory.new

    result = execute code, std_out, std_err, file, codegen: false, macro_code_coverage: true

    fail std_err.to_s, line: line if result.success?
    std_err.to_s.should contain(message), line: line
    std_err.close

    # Ignore coverage report output if the output dir is not defined, or if there is no report.
    # TODO: Maybe default this to something?
    if !std_out.empty? && (macro_coverage_output_dir = ENV["ATHENA_SPEC_COVERAGE_OUTPUT_DIR"]?.presence)
      File.open ::Path[macro_coverage_output_dir, "macro_coverage.#{Path[file].stem}:#{line}.codecov.json"], "w" do |coverage_report|
        IO.copy std_out.rewind, coverage_report
      end
    end

    std_out.close
  end

  # Executes the provided Crystal *code* and asserts it results in a runtime error with the provided *message*.
  # This can be helpful in order to test something in isolation, without affecting other test cases.
  #
  # ```
  # ASPEC::Methods.assert_runtime_error "Oh noes!", <<-CR
  #  raise "Oh noes!"
  # CR
  # ```
  #
  # NOTE: When files are required within the *code*, they are relative to the file calling this method.
  def assert_runtime_error(message : String, code : String, *, line : Int32 = __LINE__, file : String = __FILE__) : Nil
    buffer = IO::Memory.new
    result = execute code, buffer, buffer, file, codegen: true

    fail buffer.to_s, line: line if result.success?
    buffer.to_s.should contain(message), line: line
    buffer.close
  end

  # Similar to `.assert_compile_time_error`, but asserts the provided Crystal *code* successfully compiles.
  #
  # ```
  # ASPEC::Methods.assert_compiles <<-CR
  #   raise "Still passes"
  # CR
  # ```
  #
  # NOTE: When files are required within the *code*, they are relative to the file calling this method.
  def assert_compiles(code : String, *, line : Int32 = __LINE__, file : String = __FILE__) : Nil
    buffer = IO::Memory.new
    result = execute code, buffer, buffer, file, codegen: false

    fail buffer.to_s, line: line unless result.success?
    buffer.close
  end

  # Similar to `.assert_runtime_error`, but asserts the provided Crystal *code* successfully executes.
  #
  # ```
  # ASPEC::Methods.assert_executes <<-CR
  #   puts 2 + 2
  # CR
  # ```
  #
  # NOTE: When files are required within the *code*, they are relative to the file calling this method.
  def assert_executes(code : String, *, line : Int32 = __LINE__, file : String = __FILE__) : Nil
    buffer = IO::Memory.new
    result = execute code, buffer, buffer, file, codegen: true

    fail buffer.to_s, line: line unless result.success?
    buffer.close
  end

  private def execute(code : String, std_out : IO, std_err : IO, file : String, codegen : Bool, macro_code_coverage : Bool = false) : Process::Status
    input = IO::Memory.new <<-CR
      #{code}
    CR

    args = [] of String

    if macro_code_coverage
      args.push "tool", "macro_code_coverage"
    else
      args << "run"
    end

    args << "--no-color"
    args.push "--stdin-filename", file
    args << "--no-codegen" if !macro_code_coverage && !codegen

    Process.run(ENV["CRYSTAL"]? || "crystal", args, input: input.rewind, output: std_out, error: std_err)
  end

  # Runs the executable at the given *path*, optionally with the provided *args*.
  #
  # The standard output, error output, and status of the execution are yielded.
  #
  # ```
  # require "athena-spec"
  #
  # ASPEC::Methods.run_executable "/usr/bin/ls" do |output, error, status|
  #   output # => "docs\n" + "LICENSE\n" + "README.md\n" + "shard.yml\n" + "spec\n" + "src\n"
  #   error  # => ""
  #   status # => #<Process::Status:0x7f7bc9befb70 @exit_status=0>
  # end
  # ```
  def run_executable(path : String, args : Array(String) = [] of String, & : String, String, Process::Status ->) : Nil
    run_executable path, IO::Memory.new, args do |output_io, error_io, status|
      yield output_io, error_io, status
    end
  end

  # Runs the executable at the given *path*, with the given *input*, optionally with the provided *args*.
  #
  # The standard output, error output, and status of the execution are yielded.
  #
  # ```
  # require "athena-spec"
  #
  # input = IO::Memory.new %({"id":1})
  #
  # ASPEC::Methods.run_executable "jq", input, [".", "-c"] do |output, error, status|
  #   output # => "{\"id\":1}\n"
  #   error  # => ""
  #   status # => #<Process::Status:0x7f26ec698b70 @exit_status=0>
  # end
  #
  # invalid_input = IO::Memory.new %({"id"1})
  #
  # ASPEC::Methods.run_executable "jq", invalid_input, [".", "-c"] do |output, error, status|
  #   output # => ""
  #   error  # => "parse error: Expected separator between values at line 1, column 7\n"
  #   status # => #<Process::Status:0x7f0217496900 @exit_status=1024>
  # end
  # ```
  def run_executable(path : String, input : IO, args : Array(String) = [] of String, & : String, String, Process::Status ->) : Nil
    output_io = IO::Memory.new
    error_io = IO::Memory.new
    status = Process.run path, args, error: error_io, output: output_io, input: input
    yield output_io.to_s, error_io.to_s, status
  end
end
