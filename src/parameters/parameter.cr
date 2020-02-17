require "./parameter"

module Athena::Routing::Parameters
  # Parent type of a parameter just used for typing.
  #
  # See `ART::Parameters::Parameter`.
  abstract struct Param; end

  # Base type of a parameter.  Implements logic common to every parameter.
  abstract struct Parameter(T) < Param
    # The name of the parameter.
    getter name : String

    # The value to use if it was not provided
    getter default : T?

    # The type of the parameter, i.e. what the type restriction in the action is.
    getter type : T.class

    def initialize(@name : String, @default : T? = nil, @type : T.class = T); end

    # Extracts `self` from *request*.
    abstract def extract(request : HTTP::Request) : String?

    # Represents `self`'s type name to use within error handling.
    abstract def parameter_type : String

    # If `nil` is a valid value for the parameter.
    def nilable? : Bool
      @type.nilable?
    end

    # If the parameter is required.
    def required? : Bool
      !nilable?
    end
  end
end
