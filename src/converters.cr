module Athena::Converters
  class RequestBody(T)
    def self.convert(body : String) : T
      model : T = T.deserialize body
      raise CrSerializer::Exceptions::ValidationException.new model.validator unless model.validator.valid?
      model
    end
  end

  class Exists(T)
    def self.convert(id : String) : T
      model = T.find id.to_i64(strict: true)
      raise NotFoundException.new "An item with the provided ID could not be found." if model.nil?
      model
    end
  end
end
