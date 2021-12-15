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

  # Runs the Crystal program at the provided *file_path* and asserts it errors with the provided *message*.
  # The main purpose of this method is to test compile time errors.
  #
  # By default, *file_path* is assumed to be within `spec/`, but can be customized via the *prefix* named argument.
  #
  # NOTE:
  #
  # ```
  # # ./spec/abstract_class.cr
  # abstract class Foo; end
  #
  # Foo.new
  # ```
  #
  # ```
  # # ./spec/abstract_class_spec.cr
  # require "athena-spec"
  #
  # ASPEC::Methods.assert_error "abstract_class.cr", "can't instantiate abstract class Foo"
  # ```
  def assert_error(file_path : String, message : String, *, prefix : String = "spec/") : Nil
    buffer = IO::Memory.new
    result = Process.run("crystal", ["run", "--no-color", "--no-codegen", "#{prefix}#{file_path}"], error: buffer)
    fail buffer.to_s if result.success?
    buffer.to_s.should contain message
    buffer.close
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
