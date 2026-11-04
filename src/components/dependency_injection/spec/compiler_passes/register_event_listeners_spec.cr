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

  it "registers services with the event dispatchers of their tags" do
    assert_compiles <<-'CR'
      @[ADI::Register(tags: [{name: "event_dispatcher.listener", dispatcher: "other_event_dispatcher"}])]
      class OtherListener
        @[AEDA::AsEventListener]
        def on_event(event : AED::GenericEvent(String, String)) : Nil
        end
      end

      @[ADI::Register(tags: [{name: "event_dispatcher.listener", dispatcher: "other_event_dispatcher"}, "event_dispatcher.listener"])]
      class BothListener
        @[AEDA::AsEventListener]
        def on_event(event : AED::GenericEvent(String, String)) : Nil
        end
      end

      module MyExtension
        macro included
          macro finished
            {% verbatim do %}
              {%
                SERVICE_HASH["other_event_dispatcher"] = {
                  class:  AED::EventDispatcher,
                  public: true,
                }
              %}
            {% end %}
          end
        end
      end

      ADI.add_compiler_pass MyExtension, :before_optimization, 1028

      macro finished
        macro finished
          \{%
            global_calls = ADI::ServiceContainer::SERVICE_HASH["event_dispatcher"]["calls"].map { |(_, args)| args[0].stringify }
            other_calls = ADI::ServiceContainer::SERVICE_HASH["other_event_dispatcher"]["calls"].map { |(_, args)| args[0].stringify }
          %}
          ASPEC.compile_time_assert(\{{ other_calls == ["other_listener", "both_listener"] }}, "Expected the listeners to be registered with the event dispatcher of their tag")
          ASPEC.compile_time_assert(\{{ !global_calls.includes? "other_listener" }}, "Expected the listener to not be registered with the global event dispatcher")
          ASPEC.compile_time_assert(\{{ global_calls.includes? "both_listener" }}, "Expected a tag without a dispatcher to register the listener with the global event dispatcher")
        end
      end
    CR
  end

  it "errors if the event dispatcher of a listener does not exist" do
    assert_compile_time_error "Service 'my_listener' is a listener of the 'missing_event_dispatcher' event dispatcher, which does not exist.", <<-'CR'
      @[ADI::Register(tags: [{name: "event_dispatcher.listener", dispatcher: "missing_event_dispatcher"}])]
      class MyListener
        @[AEDA::AsEventListener]
        def on_event(event : AED::GenericEvent(String, String)) : Nil
        end
      end

      ADI.container.event_dispatcher
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
