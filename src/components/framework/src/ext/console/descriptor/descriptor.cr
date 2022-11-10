# :nodoc:
abstract class Athena::Framework::Console::Descriptor
  include Athena::Console::Descriptor::Interface

  getter! output : ACON::Output::Interface

  class RoutingContext < ACON::Descriptor::Context
    getter name : String?
    getter output : ACON::Output::Interface?
    getter? show_controllers : Bool

    def initialize(
      @output : ACON::Output::Interface? = nil,
      @name : String? = nil,
      @show_controllers : Bool = false,
      format : String = "txt",
      raw_text : Bool = false,
      raw_output : Bool? = nil,
      namespace : String? = nil,
      total_width : Int32? = nil,
      short : Bool = false
    )
      super format, raw_text, raw_output, namespace, total_width, short
    end
  end

  def describe(output : ACON::Output::Interface, object : _, context : ACON::Descriptor::Context) : Nil
    @output = output

    self.describe object, context
  end

  protected abstract def describe(route : ART::Route, context : RoutingContext) : Nil
  protected abstract def describe(routes : ART::RouteCollection, context : RoutingContext) : Nil

  protected def describe(obj : _, context : ACON::Descriptor::Context) : Nil
    raise "BUG: Failed to describe #{obj}"
  end

  protected def write(content : String, decorated : Bool = false) : Nil
    self.output.print content, output_type: decorated ? Athena::Console::Output::Type::NORMAL : Athena::Console::Output::Type::RAW
  end
end
