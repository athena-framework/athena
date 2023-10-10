require "ecr"

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

# Athena's Console component, `ACON` for short, allows for the creation of command-line based `ACON::Command`s.
# These commands could be used for any reoccurring task such as cron jobs, imports, etc.
# All commands belong to an `ACON::Application`, that can be extended to better fit a specific project's needs.
#
# `Athena::Console` also provides various utility/helper features, including:
#
# * Asking `ACON::Question`s
# * Reusable output [styles][Athena::Console::Formatter::OutputStyleInterface]
# * High level reusable formatting [styles][Athena::Console::Style::Interface]
# * [Testing abstractions][Athena::Console::Spec]
# * [Tab Completion][Athena::Console::Input::Interface--argumentoption-value-completion]
# * Rendering `ACON::Helper::Table`s, `ACON::Helper::ProgressBar`s, or `ACON::Helper::ProgressIndicator`s.
#
# The console component best works in conjunction with a dedicated Crystal file that'll be used as the entry point.
# Ideally this file is compiled into a dedicated binary for use in production, but is invoked directly while developing.
# Otherwise, any changes made to the files it requires would not be represented.
# The most basic example would be:
#
# ```
# #!/usr/bin/env crystal
#
# # Require the component and anything extra needed based on your business logic.
# require "athena-console"
#
# # Create an ACON::Application, passing it the name of your CLI.
# # Optionally accepts a second argument representing the version of the CLI.
# application = ACON::Application.new "My CLI"
#
# # Add any commands defined externally,
# # or configure/customize the application as needed.
#
# # Run the application.
# # By default this uses STDIN and STDOUT for its input and output.
# application.run
# ```
#
# The [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) allows executing the file as a command without needing the `crystal` prefix.
# For example `./console list` would list all commands.
#
# External commands can be registered via `ACON::Application#add`:
#
# ```
# application.add MyCommand.new
# ```
#
# The `ACON::Application#register` method may also be used to define simpler/generic commands:
#
# ```
# application.register "foo" do |input, output|
#   # Do stuff here.
#
#   # Denote that this command has finished successfully.
#   ACON::Command::Status::SUCCESS
# end
# ```
#
# ## Getting Started
#
# If using this component outside of the [Athena Framework][Athena::Framework], you will first need to add it as a dependency:
#
# ```yaml
# dependencies:
#   athena-console:
#     github: athena-framework/console
#     version: ~> 0.3.0
# ```
#
# Then run `shards install`.
#
# From here you can then setup your entry point file talked about earlier, being sure to require the component via `require "athena-console"`.
# Finally, create/require your `ACON::Command`s, and customize the `ACON::Application` as needed.
#
# TIP: If using this component with the `Athena::DependencyInjection` component, `ACON::Command` that have the `ADI::Register` annotation will automatically
# be registered as commands when using the `ADI::Console::Application` type.
#
# ### Console Completion
#
# Athena's completion script can be installed to provide auto tab completion out of the box for command and option names, and values in some cases.
# The script currently supports the shells: `bash` (also requires the `bash-completion` package).
# Run `./console completion --help` for installation instructions based on your shell.
#
# NOTE: The completion script only needs to be installed _once_, but is specific to the binary used to generate it.
# E.g. `./console completion` would be scoped to the `console` binary, while `./myapp completion` would be scoped to `myapp`.
#
# Once installed, restart your terminal, and you should be good to go!
#
# WARNING: The completion script may only be used with real built binaries, not temporary ones such as `crystal run src/console.cr -- completion`.
# This is to ensure the performance of the script is sufficient, and to avoid any issues with the naming of the temporary binary.
module Athena::Console
  VERSION = "0.3.3"

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

  # :nodoc:
  #
  # TODO: Remove this in favor of `::System::EOL` when/if https://github.com/crystal-lang/crystal/pull/11303 is released.
  module System
    EOL = {% if flag? :windows %}
            "\r\n"
          {% else %}
            "\n"
          {% end %}
  end
end
