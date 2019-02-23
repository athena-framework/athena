module Athena::Routing::Converters
  # Resolves the request body into type `T`.
  struct RequestBody(T, P)
    # Deserializes the request body into an object of `T`.
    # Raises a `CrSerializer::Exceptions::ValidationException` if the object is not valid.
    #
    # NOTE: Requires `T` to include `CrSerializer` or implements a `self.deserialize(body : String) : self` method to instantiate the object from the request body.
    def self.convert(body : String) : T
      model : T = T.from_json body
      raise CrSerializer::Exceptions::ValidationException.new model.validator unless model.validator.valid?
      model.new_record = false
      model
    end
  end

  # Resolves a path param into type `T`.
  struct Exists(T, P)
    # Resolves an object of `T` with an *id* of type `P`.
    # Raises a `NotFoundException` if the *find* method returns nil.
    #
    # NOTE: Requires `T` implements a `self.find(val : String) : self` method that returns the corresponding record, or nil.
    def self.convert(id : String) : T
      model = T.find Athena::Types.convert_type id, P
      raise AthenaException.new 404, "An item with the provided ID could not be found." if model.nil?
      model.new_record = false
      model
    end
  end
end
