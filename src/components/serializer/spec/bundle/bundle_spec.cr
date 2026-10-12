require "../spec_helper"
require "../../src/bundle/bundle"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: <<-'CR'
    require "../spec_helper.cr"
    require "../../src/bundle.cr"

    @[ADI::Register(public: true)]
    class SerializerConsumer
      def initialize(@serializer : ASR::SerializerInterface); end
    end
  CR
end

describe ASR::Bundle, tags: "compiled" do
  it "registers the serializer services" do
    assert_compiles <<-'CR'
      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH

            serializer = sh["serializer"]
            navigator_factory = sh["serializer_navigator_factory"]
            object_constructor = sh["serializer_object_constructor"]
          %}
          ASPEC.compile_time_assert(\{{ serializer["class"].resolve == Athena::Serializer::Serializer }}, "Expected serializer class to be Athena::Serializer::Serializer")
          ASPEC.compile_time_assert(\{{ navigator_factory["class"].resolve == Athena::Serializer::Navigators::NavigatorFactory }}, "Expected navigator factory class to be Athena::Serializer::Navigators::NavigatorFactory")
          ASPEC.compile_time_assert(\{{ object_constructor["class"].resolve == Athena::Serializer::InstantiateObjectConstructor }}, "Expected object constructor class to be Athena::Serializer::InstantiateObjectConstructor")
        end
      end
    CR
  end

  it "wires the services together via their interfaces" do
    assert_compiles <<-'CR'
      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH
          %}
          ASPEC.compile_time_assert(\{{ sh["serializer_consumer"]["parameters"]["serializer"]["value"].stringify == "serializer" }}, "Expected the serializer to be injected via ASR::SerializerInterface")
          ASPEC.compile_time_assert(\{{ sh["serializer"]["parameters"]["navigator_factory"]["value"].stringify == "serializer_navigator_factory" }}, "Expected the navigator factory to be injected via ASR::Navigators::NavigatorFactoryInterface")
          ASPEC.compile_time_assert(\{{ sh["serializer_navigator_factory"]["parameters"]["object_constructor"]["value"].stringify == "serializer_object_constructor" }}, "Expected the object constructor to be injected via ASR::ObjectConstructorInterface")
        end
      end
    CR
  end
end
