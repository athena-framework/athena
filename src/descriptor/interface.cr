module Athena::Console::Descriptor::Interface
  abstract def describe(output : ACON::Output::Interface, object : _, context : ACON::Descriptor::Context) : Nil
end
