require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
  CR
end

module AutoWireInterface; end

@[ADI::Register]
record AutoWireOne do
  include AutoWireInterface
end

@[ADI::Register]
record AutoWireTwo do
  include AutoWireInterface
end

@[ADI::Register(public: true)]
record AutoWireService, auto_wire_two : AutoWireInterface

module SameInstanceAliasInterface; end

@[ADI::Register]
@[ADI::AsAlias]
class SameInstancePrimary
  include SameInstanceAliasInterface
end

@[ADI::Register(public: true)]
record SameInstanceClient, a : SameInstancePrimary, b : SameInstanceAliasInterface

# Named alias tests
module NamedAliasInterface; end

@[ADI::Register]
@[ADI::AsAlias(NamedAliasInterface, name: "file_logger")]
class FileLoggerImpl
  include NamedAliasInterface
end

@[ADI::Register]
@[ADI::AsAlias(NamedAliasInterface, name: "console_logger")]
class ConsoleLoggerImpl
  include NamedAliasInterface
end

@[ADI::Register(public: true)]
record NamedAliasService, file_logger : NamedAliasInterface, console_logger : NamedAliasInterface

# Fallback alias tests
module FallbackInterface; end

@[ADI::Register]
@[ADI::AsAlias(FallbackInterface, name: "specific")]
class SpecificImpl
  include FallbackInterface
end

@[ADI::Register]
@[ADI::AsAlias(FallbackInterface)]
class DefaultImpl
  include FallbackInterface
end

@[ADI::Register(public: true)]
record FallbackService, specific : FallbackInterface, other : FallbackInterface

describe ADI::ServiceContainer do
  describe "compiler errors", tags: "compiled" do
    it "does not resolve an un-aliased interface when there is only 1 implementation" do
      assert_compile_time_error "Failed to resolve argument for service 'bar' (Bar).", <<-CR
        module SomeInterface; end

        @[ADI::Register]
        class Foo
          include SomeInterface
        end

        @[ADI::Register(public: true)]
        record Bar, a : SomeInterface

        ADI.container.bar
      CR
    end
  end

  it "resolves the service with a matching constructor name" do
    ADI.container.auto_wire_service.auto_wire_two.should be_a AutoWireTwo
  end

  it "resolves aliases to the same underlying instance" do
    service = ADI.container.same_instance_client
    service.a.should be service.b
  end

  it "resolves named aliases by parameter name" do
    service = ADI.container.named_alias_service
    service.file_logger.should be_a FileLoggerImpl
    service.console_logger.should be_a ConsoleLoggerImpl
  end

  it "falls back to type-only alias when no named match" do
    service = ADI.container.fallback_service
    service.specific.should be_a SpecificImpl
    service.other.should be_a DefaultImpl
  end
end
