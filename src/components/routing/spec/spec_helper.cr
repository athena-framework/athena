require "spec"
require "athena-spec"
require "../src/athena-routing"

require "log/spec"

ASPEC.run_all

Spec.before_each do
  ART::RouteProvider.reset
end

Log.setup :none

# FIXME: Refactor these specs to not depend on calling a protected method.
include Athena::Routing
