require "./spec_helper"

# Changes here should also be reflected in `framework/spec/ext/event_dispatcher/register_listeners_spec.cr`
describe Athena::EventDispatcher do
  describe "compiler errors", tags: "compiled" do
    it "when the listener method is static" do
      ASPEC::Methods.assert_error "Event listener methods can only be defined as instance methods. Did you mean 'MyListener#listener'?", <<-CR
        require "./spec_helper.cr"
        class MyListener
          @[AEDA::AsEventListener]
          def self.listener(blah : AED::GenericEvent(String, String)) : Nil
          end
        end
        AED::EventDispatcher.new.listener MyListener.new
      CR
    end

    it "with no parameters" do
      ASPEC::Methods.assert_error "Expected 'MyListener#listener' to have 1..2 parameters, got '0'.", <<-CR
        require "./spec_helper.cr"
        class MyListener
          @[AEDA::AsEventListener]
          def listener : Nil
          end
        end
        AED::EventDispatcher.new.listener MyListener.new
      CR
    end

    it "with too many parameters" do
      ASPEC::Methods.assert_error "Expected 'MyListener#listener' to have 1..2 parameters, got '3'.", <<-CR
        require "./spec_helper.cr"
        class MyListener
          @[AEDA::AsEventListener]
          def listener(foo, bar, baz) : Nil
          end
        end
        AED::EventDispatcher.new.listener MyListener.new
      CR
    end

    it "first parameter unrestricted" do
      ASPEC::Methods.assert_error "Expected parameter #1 of 'MyListener#listener' to have a type restriction of an 'AED::Event' instance, but it is not restricted.", <<-CR
        require "./spec_helper.cr"
        class MyListener
          @[AEDA::AsEventListener]
          def listener(foo) : Nil
          end
        end
        AED::EventDispatcher.new.listener MyListener.new
      CR
    end

    it "first parameter non AED::Event restriction" do
      ASPEC::Methods.assert_error "Expected parameter #1 of 'MyListener#listener' to have a type restriction of an 'AED::Event' instance, not 'String'.", <<-CR
        require "./spec_helper.cr"
        class MyListener
          @[AEDA::AsEventListener]
          def listener(foo : String) : Nil
          end
        end
        AED::EventDispatcher.new.listener MyListener.new
      CR
    end

    it "second parameter unrestricted" do
      ASPEC::Methods.assert_error "Expected parameter #2 of 'MyListener#listener' to have a type restriction of 'AED::EventDispatcherInterface', but it is not restricted.", <<-CR
        require "./spec_helper.cr"
        class MyListener
          @[AEDA::AsEventListener]
          def listener(foo : AED::GenericEvent(String, String), dispatcher) : Nil
          end
        end
        AED::EventDispatcher.new.listener MyListener.new
      CR
    end

    it "second parameter non AED::EventDispatcherInterface restriction" do
      ASPEC::Methods.assert_error "Expected parameter #2 of 'MyListener#listener' to have a type restriction of 'AED::EventDispatcherInterface', not 'String'.", <<-CR
        require "./spec_helper.cr"
        class MyListener
          @[AEDA::AsEventListener]
          def listener(foo : AED::GenericEvent(String, String), dispatcher : String) : Nil
          end
        end
        AED::EventDispatcher.new.listener MyListener.new
      CR
    end

    it "non integer priority field" do
      ASPEC::Methods.assert_error "Event listener method 'MyListener#listener' expects a 'NumberLiteral' for its 'AEDA::AsEventListener#priority' field, but got a 'StringLiteral'.", <<-CR
        require "./spec_helper.cr"
        class MyListener
          @[AEDA::AsEventListener(priority: "foo")]
          def listener(foo : AED::GenericEvent(String, String)) : Nil
          end
        end
        AED::EventDispatcher.new.listener MyListener.new
      CR
    end
  end
end
