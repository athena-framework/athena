require "../spec_helper"
require "./object_provider"

abstract struct AbstractDescriptorTestCase < ASPEC::TestCase
  @[DataProvider("input_argument_test_data")]
  def test_describe_input_argument(object : ACON::Input::Argument, expected : String) : Nil
    self.assert_description expected, object
  end

  @[DataProvider("input_option_test_data")]
  def test_describe_input_option(object : ACON::Input::Option, expected : String) : Nil
    self.assert_description expected, object
  end

  @[DataProvider("input_definition_test_data")]
  def test_describe_input_definition(object : ACON::Input::Definition, expected : String) : Nil
    self.assert_description expected, object
  end

  @[DataProvider("command_test_data")]
  def test_describe_command(object : ACON::Command, expected : String) : Nil
    self.assert_description expected, object
  end

  @[DataProvider("application_test_data")]
  def test_describe_application(object : ACON::Application, expected : String) : Nil
    self.assert_description expected, object
  end

  def input_argument_test_data : Array
    self.description_test_data ObjectProvider.input_arguments
  end

  def input_option_test_data : Array
    self.description_test_data ObjectProvider.input_options
  end

  def input_definition_test_data : Array
    self.description_test_data ObjectProvider.input_definitions
  end

  def command_test_data : Array
    self.description_test_data ObjectProvider.commands
  end

  def application_test_data : Array
    self.description_test_data ObjectProvider.applications
  end

  protected abstract def descriptor : ACON::Descriptor::Interface
  protected abstract def format : String

  protected def description_test_data(data : Hash(String, _)) : Array
    data.map do |k, v|
      normalized_path = File.join __DIR__, "..", "fixtures", "text"
      {v, File.read "#{normalized_path}/#{k}.#{self.format}"}
    end
  end

  protected def assert_description(expected : String, object, context : ACON::Descriptor::Context = ACON::Descriptor::Context.new) : Nil
    output = ACON::Output::IO.new IO::Memory.new
    context = context.clone
    context.raw_output = true
    self.descriptor.describe output, object, context
    self.normalize_output(output.to_s).should eq self.normalize_output(expected)
  end

  private def normalize_output(output : String) : String
    output.gsub(ACON::System::EOL, "\n").strip
  end
end
