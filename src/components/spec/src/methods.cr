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

  # Executes the provided Crystal *code* asserts it errors with the provided *message*.
  # The main purpose of this method is to test compile time errors.
  #
  # ```
  # ASPEC::Methods.assert_error "can't instantiate abstract class Foo", <<-CR
  #   abstract class Foo; end
  #   Foo.new
  # CR
  # ```
  #
  # NOTE: When files are required within the *code*, they are relative to the file calling this method.
  #
  # By default this method does not perform any codegen; meaning it only validates that the code can be successfully compiled,
  # excluding any runtime exceptions.
  #
  # The *codegen* option can be used to enable codegen, thus allowing runtime logic to also be tested.
  # This can be helpful in order to test something in isolation, without affecting other test cases.
  def assert_error(message : String, code : String, *, codegen : Bool = false, line : Int32 = __LINE__, file : String = __FILE__) : Nil
    buffer = IO::Memory.new
    result = execute code, buffer, file, codegen

    fail buffer.to_s, line: line if result.success?
    buffer.to_s.should contain(message), line: line
    buffer.close
  end

  # Similar to `.assert_error`, but asserts the provided Crystal *code* successfully compiles.
  #
  # ```
  # ASPEC::Methods.assert_success <<-CR
  #   puts 2 + 2
  # CR
  # ```
  #
  # NOTE: When files are required within the *code*, they are relative to the file calling this method.
  #
  # By default this method does not perform any codegen; meaning it only validates that the code can be successfully compiled,
  # excluding any runtime exceptions.
  #
  # The *codegen* option can be used to enable codegen, thus allowing runtime logic to also be tested.
  # This can be helpful in order to test something in isolation, without affecting other test cases.
  def assert_success(code : String, *, codegen : Bool = false, line : Int32 = __LINE__, file : String = __FILE__) : Nil
    buffer = IO::Memory.new
    result = execute code, buffer, file, codegen

    fail buffer.to_s, line: line unless result.success?
    buffer.close
  end

  private def execute(code : String, buffer : IO, file : String, codegen : Bool) : Process::Status
    input = IO::Memory.new <<-CR
      #{code}
    CR

    args = [
      "run",
      "--no-color",
      "--stdin-filename",
      "#{file}",
    ]

    args << "--no-codegen" unless codegen

    Process.run("crystal", args, input: input.rewind, output: buffer, error: buffer)
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
