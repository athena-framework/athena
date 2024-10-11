require "./spec/expectations/*"

# Provides helper types for testing `ACON::Command` and `ACON::Application`s.
module Athena::Console::Spec
  # Contains common logic shared by both `ACON::Spec::CommandTester` and `ACON::Spec::ApplicationTester`.
  module Tester
    @capture_stderr_separately : Bool = false

    # Returns the `ACON::Output::Interface` being used by the tester.
    getter! output : ACON::Output::Interface

    # Sets an array of values that will be used as the input to the command.
    # `RETURN` is automatically assumed after each input.
    setter inputs : Array(String) = [] of String

    # Returns the output resulting from running the command.
    # Raises if called before executing the command.
    def display(normalize : Bool = false) : String
      raise ACON::Exception::Logic.new "Output not initialized. Did you execute the command before requesting the display?" unless output = @output
      output = output.to_s

      if normalize
        output = output.gsub EOL, "\n"
      end

      output
    end

    # Returns the error output resulting from running the command.
    # Raises if `capture_stderr_separately` was not set to `true`.
    def error_output(normalize : Bool = false) : String
      raise ACON::Exception::Logic.new "The error output is not available when the test is ran without 'capture_stderr_separately' set." unless @capture_stderr_separately

      output = self.output.as(ACON::Output::ConsoleOutput).error_output.to_s

      if normalize
        output = output.gsub EOL, "\n"
      end

      output
    end

    # Helper method to setting the `#inputs=` property.
    def inputs(*args : String) : Nil
      @inputs = args.to_a
    end

    abstract def status : ACON::Command::Status?

    # Asserts that the return `#status` is successful.
    def assert_command_is_successful(message : String = "", *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
      self.status.should ACON::Spec::Expectations::CommandIsSuccessful.new, file: file, line: line, failure_message: message.presence
    end

    protected def init_output(
      decorated : Bool? = nil,
      interactive : Bool? = nil,
      verbosity : ACON::Output::Verbosity? = nil,
      @capture_stderr_separately : Bool = false,
    ) : Nil
      if !@capture_stderr_separately
        @output = ACON::Output::IO.new IO::Memory.new

        decorated.try do |d|
          self.output.decorated = d
        end

        verbosity.try do |v|
          self.output.verbosity = v
        end
      else
        @output = ACON::Output::ConsoleOutput.new(
          verbosity || ACON::Output::Verbosity::NORMAL,
          decorated
        )

        error_output = ACON::Output::IO.new IO::Memory.new
        error_output.formatter = self.output.formatter
        error_output.verbosity = self.output.verbosity
        error_output.decorated = self.output.decorated?

        self.output.as(ACON::Output::ConsoleOutput).stderr = error_output
        self.output.as(ACON::Output::IO).io = IO::Memory.new
      end
    end

    private def create_input_stream(inputs : Array(String)) : IO
      input_stream = IO::Memory.new

      inputs.each do |input|
        input_stream << "#{input}#{EOL}"
      end

      input_stream.rewind

      input_stream
    end
  end

  # Functionally similar to `ACON::Spec::CommandTester`, but used for testing entire `ACON::Application`s.
  #
  # Can be useful if your project extends the base application in order to customize it in some way.
  #
  # NOTE: Be sure to set `ACON::Application#auto_exit=` to `false`, when testing an entire application.
  struct ApplicationTester
    include Tester

    # Returns the `ACON::Application` instance being tested.
    getter application : ACON::Application

    # Returns the `ACON::Input::Interface` being used by the tester.
    getter! input : ACON::Input::Interface

    # Returns the `ACON::Command::Status` of the command execution, or `nil` if it has not yet been executed.
    getter status : ACON::Command::Status? = nil

    def initialize(@application : ACON::Application); end

    # Runs the application, with the provided *input* being used as the input of `ACON::Application#run`.
    #
    # Custom values for *decorated*, *interactive*, and *verbosity* can also be provided and will be forwarded to their respective types.
    # *capture_stderr_separately* makes it so output to `STDERR` is captured separately, in case you wanted to test error output.
    # Otherwise both error and normal output are captured via `ACON::Spec::Tester#display`.
    def run(
      decorated : Bool = false,
      interactive : Bool? = nil,
      capture_stderr_separately : Bool = false,
      verbosity : ACON::Output::Verbosity? = nil,
      **input : _,
    )
      self.run input.to_h.transform_keys(&.to_s), decorated: decorated, interactive: interactive, capture_stderr_separately: capture_stderr_separately, verbosity: verbosity
    end

    # :ditto:
    def run(
      input : Hash(String, _) = Hash(String, String).new,
      *,
      decorated : Bool? = nil,
      interactive : Bool? = nil,
      capture_stderr_separately : Bool = false,
      verbosity : ACON::Output::Verbosity? = nil,
    ) : ACON::Command::Status
      @input = ACON::Input::Hash.new input

      interactive.try do |i|
        self.input.interactive = i
      end

      unless (inputs = @inputs).empty?
        self.input.stream = self.create_input_stream inputs
      end

      self.init_output(
        decorated: decorated,
        interactive: interactive,
        capture_stderr_separately: capture_stderr_separately,
        verbosity: verbosity
      )

      @status = @application.run self.input, self.output
    end
  end

  # Allows testing the logic of an `ACON::Command`, without needing to create and run a binary.
  #
  # Say we have the following command:
  #
  # ```
  # @[ACONA::AsCommand("add", description: "Sums two numbers, optionally making making the sum negative")]
  # class AddCommand < ACON::Command
  #   protected def configure : Nil
  #     self
  #       .argument("value1", :required, "The first value")
  #       .argument("value2", :required, "The second value")
  #       .option("negative", description: "If the sum should be made negative")
  #   end
  #
  #   protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
  #     sum = input.argument("value1", Int32) + input.argument("value2", Int32)
  #
  #     sum = -sum if input.option "negative", Bool
  #
  #     output.puts "The sum of values is: #{sum}"
  #
  #     ACON::Command::Status::SUCCESS
  #   end
  # end
  # ```
  #
  # We can use `ACON::Spec::CommandTester` to assert it is working as expected.
  #
  # ```
  # require "spec"
  # require "athena-spec"
  #
  # describe AddCommand do
  #   describe "#execute" do
  #     it "without negative option" do
  #       tester = ACON::Spec::CommandTester.new AddCommand.new
  #       tester.execute value1: 10, value2: 7
  #       tester.display.should eq "The sum of the values is: 17\n"
  #     end
  #
  #     it "with negative option" do
  #       tester = ACON::Spec::CommandTester.new AddCommand.new
  #       tester.execute value1: -10, value2: 5, "--negative": nil
  #       tester.display.should eq "The sum of the values is: 5\n"
  #     end
  #   end
  # end
  # ```
  #
  # ### Commands with User Input
  #
  # A command that are asking `ACON::Question`s can also be tested:
  #
  # ```
  # @[ACONA::AsCommand("question")]
  # class QuestionCommand < ACON::Command
  #   protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
  #     helper = self.helper ACON::Helper::Question
  #
  #     question = ACON::Question(String).new "What is your name?", "None"
  #     output.puts "Your name is: #{helper.ask input, output, question}"
  #
  #     ACON::Command::Status::SUCCESS
  #   end
  # end
  # ```
  #
  # ```
  # require "spec"
  # require "./src/spec"
  #
  # describe QuestionCommand do
  #   describe "#execute" do
  #     it do
  #       command = QuestionCommand.new
  #       command.helper_set = ACON::Helper::HelperSet.new ACON::Helper::Question.new
  #       tester = ACON::Spec::CommandTester.new command
  #       tester.inputs "Jim"
  #       tester.execute
  #       tester.display.should eq "What is your name?Your name is: Jim\n"
  #     end
  #   end
  # end
  # ```
  #
  # Because we are not in the context of an `ACON::Application`, we need to manually set the `ACON::Helper::HelperSet`
  # in order to make the command aware of `ACON::Helper::Question`. After that we can use the `ACON::Spec::Tester#inputs` method
  # to set the inputs our test should use when prompted.
  #
  # Multiple inputs can be provided if there are multiple questions being asked.
  struct CommandTester
    include Tester

    # Returns the `ACON::Input::Interface` being used by the tester.
    getter! input : ACON::Input::Interface

    # Returns the `ACON::Command::Status` of the command execution, or `nil` if it has not yet been executed.
    getter status : ACON::Command::Status? = nil

    def initialize(@command : ACON::Command); end

    # Executes the command, with the provided *input* being passed to the command.
    #
    # Custom values for *decorated*, *interactive*, and *verbosity* can also be provided and will be forwarded to their respective types.
    # *capture_stderr_separately* makes it so output to `STDERR` is captured separately, in case you wanted to test error output.
    # Otherwise both error and normal output are captured via `ACON::Spec::Tester#display`.
    def execute(
      decorated : Bool = false,
      interactive : Bool? = nil,
      capture_stderr_separately : Bool = false,
      verbosity : ACON::Output::Verbosity? = nil,
      **input : _,
    )
      self.execute input.to_h.transform_keys(&.to_s), decorated: decorated, interactive: interactive, capture_stderr_separately: capture_stderr_separately, verbosity: verbosity
    end

    # :ditto:
    def execute(
      input : Hash(String, _) = Hash(String, String).new,
      *,
      decorated : Bool = false,
      interactive : Bool? = nil,
      capture_stderr_separately : Bool = false,
      verbosity : ACON::Output::Verbosity? = nil,
    ) : ACON::Command::Status
      if !input.has_key?("command") && (application = @command.application?) && application.definition.has_argument?("command")
        input = input.merge({"command" => @command.name})
      end

      @input = ACON::Input::Hash.new input
      self.input.stream = self.create_input_stream @inputs

      interactive.try do |i|
        self.input.interactive = i
      end

      self.init_output(
        decorated: decorated,
        interactive: interactive,
        capture_stderr_separately: capture_stderr_separately,
        verbosity: verbosity
      )

      @status = @command.run self.input, self.output
    end
  end

  struct CommandCompletionTester
    def initialize(@command : ACON::Command); end

    def complete(*input : String) : Array(String)
      self.complete input
    end

    def complete(input : Enumerable(String)) : Array(String)
      completion_input = ACON::Completion::Input.from_tokens input, (input.size - 1).clamp(0, nil)
      completion_input.bind @command.definition
      suggestions = ACON::Completion::Suggestions.new

      @command.complete completion_input, suggestions

      options = [] of String

      suggestions.suggested_options.each do |option|
        options << "--#{option.name}"
      end

      options.concat suggestions.suggested_values.map(&.to_s)
    end
  end
end
