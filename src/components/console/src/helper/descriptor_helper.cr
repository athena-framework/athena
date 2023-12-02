# :nodoc:
class Athena::Console::Helper::Descriptor < Athena::Console::Helper
  @descriptors = Hash(String, ACON::Descriptor::Interface).new

  def initialize
    self.register "txt", ACON::Descriptor::Text.new
  end

  def describe(output : ACON::Output::Interface, object : _, context : ACON::Descriptor::Context) : Nil
    raise "Unsupported format #{context.format}." unless descriptor = @descriptors[context.format]?

    descriptor.describe output, object, context
  end

  def register(format : String, descriptor : ACON::Descriptor::Interface) : self
    @descriptors[format] = descriptor

    self
  end

  def formats : Array(String)
    @descriptors.keys
  end
end
