require "spec"
require "athena-spec"
require "../src/athena-http"

# Optional component `AHTTP::Session::Storage::MetadataBag` uses, required after the HTTP component as it may be in an application.
require "athena-clock"
require "athena-clock/spec"

ASPEC.run_all
