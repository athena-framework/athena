module Athena::Converters
  class RequestBody(T)
    def self.convert(body : String) : T
      model : T = T.deserialize body
      raise CrSerializer::Exceptions::ValidationException.new model.validator unless model.validator.valid?
      model
    end
  end
end
