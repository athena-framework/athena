# Represents a URL generator that can be configured whether an exception should be generated when the parameters do not match the requirements.
module Athena::Routing::Generator::ConfigurableRequirementsInterface
  # Sets how invalid parameters should be treated:
  #
  # * `true` - Raise an exception for mismatched requirements.
  # * `false` - Do not raise an exception, but return an empty string.
  # * `nil` - Disables checks, returning a URL with possibly invalid parameters.
  abstract def strict_requirements=(enabled : Bool?)

  # Returns the current strict requirements mode.
  abstract def strict_requirements? : Bool?
end
