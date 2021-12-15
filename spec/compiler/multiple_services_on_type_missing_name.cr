require "../spec_helper"

class MissingService
end

@[ADI::Register(_id: 1, name: "one")]
@[ADI::Register(_id: 2)]
class Klass
  def initialize(@id : Int32); end
end

ADI::ServiceContainer.new
