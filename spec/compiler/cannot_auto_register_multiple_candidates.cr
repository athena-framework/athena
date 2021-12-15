require "../spec_helper"

module Interface
end

@[ADI::Register]
class One
  include Interface
end

@[ADI::Register]
class Two
  include Interface
end

@[ADI::Register]
class Klass
  def initialize(@service : Interface); end
end

ADI::ServiceContainer.new
