require "../spec_helper"

@[ATHA::Prefix]
abstract class PrefixController < Athena::Framework::Controller
end

class CompileController < PrefixController
end

ATH.run
