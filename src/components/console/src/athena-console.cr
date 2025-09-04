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
require "./exception/*"
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
  VERSION = "0.4.2"

  # Contains all the `Athena::Console` based annotations.
  module Annotations; end

  # Includes the commands that come bundled with `Athena::Console`.
  module Commands; end

  # Includes types related to Athena's [tab completion][Athena::Console::Input::Interface--argumentoption-value-completion] features.
  module Completion; end

  # Both acts as a namespace for exceptions related to the `Athena::Console` component, as well as a way to check for exceptions from the component.
  # Exposes a `#code` method that represents the exit code of a command invocation.
  module Exception
    # Returns the exit code that should be used for this exception.
    getter code : Int32
  end

  # Contains types related to lazily loading commands.
  module Loader; end
end
