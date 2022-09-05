require "spec"
require "athena-spec"
require "../src/athena-routing"

ASPEC.run_all

Spec.before_each do
  ART::RouteProvider.reset
end

# FIXME: Refactor these specs to not depend on calling a protected method.
include Athena::Routing
