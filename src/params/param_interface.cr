module Athena::Routing::Params::ParamInterfaceBase; end

module Athena::Routing::Params::ParamInterface(T)
  include Athena::Routing::Params::ParamInterfaceBase

  # Name of the param, maps to the route action argument name.
  abstract def name : String

  abstract def default : T?

  abstract def incompatibilities : Array(String)

  abstract def constraints : Array(AVD::Constraint)

  abstract def strict? : Bool

  abstract def parse_value(request : HTTP::Request, default)
end
