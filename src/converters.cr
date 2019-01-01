module Athena::Converters
  # Resolves the request body into type `T`.
  struct RequestBody(T)
    # Deserializes the request body into an object of `T`.
    # Raises a `CrSerializer::Exceptions::ValidationException` if the object is not valid.
    def self.convert(body : String) : T
      model : T = T.deserialize body
      raise CrSerializer::Exceptions::ValidationException.new model.validator unless model.validator.valid?
      model
    end
  end

  # Resolves a path param into type `T`.
  struct Exists(T)
    # Resolves an object of `T` with an id of *id*.
    # Raises a `NotFoundException` if the *find* method returns nil.
    #
    # NOTE: Assumes `T` implements a *find* method that returns the corresponding record, or nil.
    def self.convert(id : String) : T
      model = T.find id.to_i64(strict: true)
      raise NotFoundException.new "An item with the provided ID could not be found." if model.nil?
      model
    end
  end
end
