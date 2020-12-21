require "../spec_helper"

@[ARTA::Prefix]
abstract class PrefixController < Athena::Routing::Controller
end

class CompileController < PrefixController
end

ART.run
