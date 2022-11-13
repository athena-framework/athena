# :nodoc:
class Athena::Framework::Console::Helper::Descriptor < Athena::Console::Helper::Descriptor
  def initialize
    self.register "txt", ATH::Console::Descriptor::Text.new
  end
end
