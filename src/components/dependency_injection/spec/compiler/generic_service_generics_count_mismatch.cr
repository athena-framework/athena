require "../spec_helper"

@[ADI::Register(Int32, name: "generic_service")]
class GenericService(A, B)
  def initialize(@value : B); end
end

ADI::ServiceContainer.new
