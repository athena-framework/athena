require "./converter"

module Athena::Routing::Converters
  # Resolves the request body into type `T`.
  struct RequestBody(T, P) < Converter(T, P)
    # Deserializes the request body into an object of `T`.
    # Raises a `CrSerializer::Exceptions::ValidationException` if the object is not valid.
    #
    # NOTE: Requires `T` to include `CrSerializer` or implements a `self.from_json(body : String) : self` method to instantiate the object from the request body.
    def convert(body : String) : T
      model : T = T.from_json body
      raise CrSerializer::Exceptions::ValidationException.new model.@validator unless model.valid?
      model
    end
  end
end
