require "../spec_helper"

@[ADI::Register(_values: [[[1]]])]
class Klass
  def initialize(@values : Array(Array(Array(Int32)))); end
end

ADI::ServiceContainer.new
