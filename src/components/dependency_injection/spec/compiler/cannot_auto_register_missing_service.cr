require "../spec_helper"

class MissingService
end

@[ADI::Register]
class Klass
  def initialize(@service : MissingService); end
end

ADI::ServiceContainer.new
