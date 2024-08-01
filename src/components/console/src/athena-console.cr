require "ecr"
require "semantic_version"

require "athena-clock"

require "./annotations"
require "./application"
require "./command"
require "./cursor"
require "./terminal"

require "./commands/*"
require "./completion/**"
require "./descriptor/*"
require "./exceptions/*"
require "./formatter/*"
require "./helper/*"
require "./input/*"
require "./loader/*"
require "./output/*"
require "./question/*"
require "./style/*"

# Convenience alias to make referencing `Athena::Console` types easier.
alias ACON = Athena::Console

# Convenience alias to make referencing `ACON::Annotations` types easier.
alias ACONA = ACON::Annotations

# Allows the creation of CLI based commands
module Athena::Console
  VERSION = "0.3.6"

  # Contains all the `Athena::Console` based annotations.
  module Annotations; end

  # Includes the commands that come bundled with `Athena::Console`.
  module Commands; end

  # Includes types related to Athena's [tab completion][Athena::Console::Input::Interface--argumentoption-value-completion] features.
  module Completion; end

  # Contains all custom exceptions defined within `Athena::Console`.
  module Exceptions; end

  # Contains types related to lazily loading commands.
  module Loader; end
end
