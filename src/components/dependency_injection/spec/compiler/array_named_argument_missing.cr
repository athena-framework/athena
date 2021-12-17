require "../spec_helper"

record Foo

@[ADI::Register(_values: ["@foo"])]
class Klass
  def initialize(@values : Array(Foo)); end
end

ADI::ServiceContainer.new
