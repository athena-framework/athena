require "../spec_helper"

@[ADI::Register(name: "generic_service")]
class GenericService(T)
  def initialize(@value : T); end
end

ADI::ServiceContainer.new
