require "../spec_helper"

@[ADI::Register(generics: {Int32})]
class GenericService(T)
  def initialize(@value : T); end
end

ADI::ServiceContainer.new
