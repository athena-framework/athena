require "../spec_helper"

@[ART::Prefix]
abstract class PrefixController < Athena::Routing::Controller
end

class CompileController < PrefixController
end

ART.run
