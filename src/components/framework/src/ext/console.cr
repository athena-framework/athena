# :nodoc:
module Athena::Framework::Console::Command
  TAG = "athena.console.command"
end

require "./console/**"

@[ADI::Autoconfigure(tags: [ATH::Console::Command::TAG])]
abstract class ACON::Command; end

# Register the console compiler pass now that the type is available.
{% Athena::Framework::Bundle::PASSES << {Athena::Framework::Console::CompilerPasses::RegisterCommands, :before_removing, nil} %}
