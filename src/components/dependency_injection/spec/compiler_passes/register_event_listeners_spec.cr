require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: <<-'CR'
    require "../spec_helper.cr"
    require "athena-event_dispatcher"
  CR
end

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: <<-'CR'
    require "../spec_helper.cr"
    require "athena-event_dispatcher"
  CR
end

describe ADI::ServiceContainer::RegisterEventListeners, tags: "compiled" do
  it "registers services with listener methods with the event dispatcher" do
    assert_compiles <<-'CR'
      @[ADI::Register]
      class MyListener
        @[AEDA::AsEventListener]
        def on_event(event : AED::GenericEvent(String, String)) : Nil
        end
      end

      @[ADI::Register]
      class NotAListener; end

      macro finished
        macro finished
          \{%
            calls = ADI::ServiceContainer::SERVICE_HASH["event_dispatcher"]["calls"].map { |(_, args)| args[0].stringify }
          %}
          ASPEC.compile_time_assert(\{{ calls.includes? "my_listener" }}, "Expected the listener to be registered with the event dispatcher")
          ASPEC.compile_time_assert(\{{ !calls.includes? "not_a_listener" }}, "Expected services without listener methods to not be registered with the event dispatcher")
        end
      end
    CR
  end

  it "errors if a listener method is a class method" do
    assert_compile_time_error "Event listener methods can only be defined as instance methods. Did you mean 'MyListener#listener'?", <<-'CR'
      @[ADI::Register]
      class MyListener
        @[AEDA::AsEventListener]
        def self.listener(event : AED::GenericEvent(String, String)) : Nil
        end
      end

      ADI.container.event_dispatcher
    CR
  end
end
