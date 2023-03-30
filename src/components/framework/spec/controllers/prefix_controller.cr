CLASS_PREFIX  = "/prefix"
METHOD_PREFIX = "/index"

@[ARTA::Route(path: CLASS_PREFIX)]
class PrefixController < ATH::Controller
  @[ARTA::Get(path: METHOD_PREFIX)]
  def index : String
    "foo"
  end
end
