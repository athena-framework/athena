require "./interface"

# :nodoc:
abstract class Athena::Console::Descriptor
  include Athena::Console::Descriptor::Interface

  getter! output : ACON::Output::Interface

  def describe(output : ACON::Output::Interface, object : _, context : ACON::Descriptor::Context) : Nil
    @output = output

    self.describe object, context
  end

  protected abstract def describe(application : ACON::Application, context : ACON::Descriptor::Context) : Nil
  protected abstract def describe(command : ACON::Command, context : ACON::Descriptor::Context) : Nil
  protected abstract def describe(definition : ACON::Input::Definition, context : ACON::Descriptor::Context) : Nil
  protected abstract def describe(argument : ACON::Input::Argument, context : ACON::Descriptor::Context) : Nil
  protected abstract def describe(option : ACON::Input::Option, context : ACON::Descriptor::Context) : Nil

  protected def describe(obj : _, context : ACON::Descriptor::Context) : Nil
    raise "BUG: Failed to describe #{obj}"
  end

  protected def write(content : String, decorated : Bool = false) : Nil
    self.output.print content, output_type: decorated ? Athena::Console::Output::Type::NORMAL : Athena::Console::Output::Type::RAW
  end
end
