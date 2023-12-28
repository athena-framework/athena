# :nodoc:
module Athena::Framework::Console::Command
  TAG = "athena.console.command"
end

require "./console/**"

ADI.auto_configure ACON::Command, {tags: [ATH::Console::Command::TAG]}
