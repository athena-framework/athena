# :nodoc:
module Athena::Framework::Console::Command
  TAG = "athena.console.command"
end

require "./console/**"

@[ADI::Autoconfigure(tags: [ATH::Console::Command::TAG])]
abstract class ACON::Command; end
