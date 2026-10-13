require "../spec_helper"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: <<-'CR'
    require "../spec_helper.cr"
    require "athena-clock"
    require "athena-clock/spec"
    require "athena-event_dispatcher"
  CR
end

describe ADI::ServiceContainer::RegisterComponentServices, tags: "compiled" do
  it "registers the services of the components that are present" do
    assert_compiles <<-'CR'
      @[ADI::Register(public: true)]
      class ComponentConsumer
        def initialize(
          @clock : ACLK::Interface,
          @dispatcher : AED::EventDispatcherInterface,
          @contracts_dispatcher : ACTR::EventDispatcher::Interface,
        ); end
      end

      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH
            parameters = sh["component_consumer"]["parameters"]
          %}
          ASPEC.compile_time_assert(\{{ sh["event_dispatcher"]["class"].resolve == Athena::EventDispatcher::EventDispatcher }}, "Expected the event dispatcher class to be Athena::EventDispatcher::EventDispatcher")
          ASPEC.compile_time_assert(\{{ parameters["clock"]["value"].stringify == "clock" }}, "Expected the clock to be injected via ACLK::Interface")
          ASPEC.compile_time_assert(\{{ parameters["dispatcher"]["value"].stringify == "event_dispatcher" }}, "Expected the event dispatcher to be injected via AED::EventDispatcherInterface")
          ASPEC.compile_time_assert(\{{ parameters["contracts_dispatcher"]["value"].stringify == "event_dispatcher" }}, "Expected the event dispatcher to be injected via ACTR::EventDispatcher::Interface")
        end
      end
    CR
  end

  it "allows applications to replace the aliases" do
    assert_compiles <<-'CR'
      @[ADI::Register]
      @[ADI::AsAlias(ACLK::Interface)]
      class FrozenClock < ACLK::Spec::MockClock; end

      @[ADI::Register(public: true)]
      class ClockConsumer
        def initialize(@time_source : ACLK::Interface); end
      end

      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH
          %}
          ASPEC.compile_time_assert(\{{ sh["clock_consumer"]["parameters"]["time_source"]["value"].stringify == "frozen_clock" }}, "Expected the replaced clock alias to be injected")
        end
      end
    CR
  end

  it "does not register services of components that are not present" do
    ASPEC::Methods.assert_compiles <<-'CR', line: __LINE__
      require "../spec_helper.cr"

      macro finished
        macro finished
          \{%
            sh = ADI::ServiceContainer::SERVICE_HASH
          %}
          ASPEC.compile_time_assert(\{{ sh["event_dispatcher"] == nil }}, "Expected the event dispatcher to not be registered")
        end
      end
    CR
  end
end
