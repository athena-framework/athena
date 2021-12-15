require "../spec_helper"

record Foo

ADI.bind values, ["@foo"]

@[ADI::Register]
class Klass
  def initialize(@values : Array(Foo)); end
end

ADI::ServiceContainer.new
