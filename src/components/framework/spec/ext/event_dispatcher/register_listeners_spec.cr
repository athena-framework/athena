require "../../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line, codegen: true
    require "../../spec_helper.cr"

    #{code}

    ATH.run
  CR
end

# Changes here should also be reflected in `event_dispatcher/spec/compiler.cr`
describe ATH do
  describe "EventDispatcher" do
    describe "compiler errors", tags: "compiled" do
      it "when the listener method is static" do
        assert_error "Event listener methods can only be defined as instance methods. Did you mean 'MyListener#listener'?", <<-CR
          @[ADI::Register]
          class MyListener
            include AED::EventListenerInterface

            @[AEDA::AsEventListener]
            def self.listener(blah : AED::GenericEvent(String, String)) : Nil
            end
          end
        CR
      end

      it "with no parameters" do
        assert_error "Expected 'MyListener#listener' to have 1..2 parameters, got '0'.", <<-CR
          @[ADI::Register]
          class MyListener
            include AED::EventListenerInterface

            @[AEDA::AsEventListener]
            def listener : Nil
            end
          end
        CR
      end

      it "with too many parameters" do
        assert_error "Expected 'MyListener#listener' to have 1..2 parameters, got '3'.", <<-CR
          @[ADI::Register]
          class MyListener
            include AED::EventListenerInterface

            @[AEDA::AsEventListener]
            def listener(foo, bar, baz) : Nil
            end
          end
        CR
      end

      it "first parameter unrestricted" do
        assert_error "Expected parameter #1 of 'MyListener#listener' to have a type restriction of an 'AED::Event' instance, but it is not restricted.", <<-CR
          @[ADI::Register]
          class MyListener
            include AED::EventListenerInterface

            @[AEDA::AsEventListener]
            def listener(foo) : Nil
            end
          end
        CR
      end

      it "first parameter non AED::Event restriction" do
        assert_error "Expected parameter #1 of 'MyListener#listener' to have a type restriction of an 'AED::Event' instance, not 'String'.", <<-CR
          @[ADI::Register]
          class MyListener
            include AED::EventListenerInterface

            @[AEDA::AsEventListener]
            def listener(foo : String) : Nil
            end
          end
        CR
      end

      it "second parameter unrestricted" do
        assert_error "Expected parameter #2 of 'MyListener#listener' to have a type restriction of 'AED::EventDispatcherInterface', but it is not restricted.", <<-CR
          @[ADI::Register]
          class MyListener
            include AED::EventListenerInterface

            @[AEDA::AsEventListener]
            def listener(foo : AED::GenericEvent(String, String), dispatcher) : Nil
            end
          end
        CR
      end

      it "second parameter non AED::EventDispatcherInterface restriction" do
        assert_error "Expected parameter #2 of 'MyListener#listener' to have a type restriction of 'AED::EventDispatcherInterface', not 'String'.", <<-CR
          @[ADI::Register]
          class MyListener
            include AED::EventListenerInterface

            @[AEDA::AsEventListener]
            def listener(foo : AED::GenericEvent(String, String), dispatcher : String) : Nil
            end
          end
        CR
      end

      it "non integer priority field" do
        assert_error "Event listener method 'MyListener#listener' expects a 'NumberLiteral' for its 'AEDA::AsEventListener#priority' field, but got a 'StringLiteral'.", <<-CR
          @[ADI::Register]
          class MyListener
            include AED::EventListenerInterface

            @[AEDA::AsEventListener(priority: "foo")]
            def listener(foo : AED::GenericEvent(String, String)) : Nil
            end
          end
        CR
      end
    end
  end
end
