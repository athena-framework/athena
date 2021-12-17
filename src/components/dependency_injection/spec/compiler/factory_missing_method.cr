require "../spec_helper"

@[ADI::Register(_value: 10, factory: "double")]
class Klass
  def self.triple(value : Int32) : self
    new value
  end

  def initialize(@value : Int32); end
end
