module Athena::Routing::Params::ParamInterface
  # Name of the param, maps to the route action argument name.
  abstract def name : String

  abstract def default

  abstract def description : String?

  abstract def incompatibilities : Array(String)?

  abstract def constraints : Array(AVD::Constraint)

  abstract def strict? : Bool

  abstract def parse_value(request : HTTP::Request, default)

  abstract def type
end
