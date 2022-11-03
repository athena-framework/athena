require "athena-console"
require "./console/*"

ADI.auto_configure ACON::Command, {tags: ["athena.console.command"]}
