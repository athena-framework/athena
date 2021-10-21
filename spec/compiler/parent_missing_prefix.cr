require "../spec_helper"

@[ARTA::Prefix]
abstract class PrefixController < Athena::Framework::Controller
end

class CompileController < PrefixController
end

ATH.run
