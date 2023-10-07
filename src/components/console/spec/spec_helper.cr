require "spec"

require "../src/athena-console"
require "../src/spec"

require "athena-spec"
require "athena-clock/spec"

require "./fixtures/commands/io"
require "./fixtures/**"

# Spec by default disables colorize with `TERM=dumb`.
# Override that given there are specs based on ansi output.
Colorize.enabled = true

ASPEC.run_all
