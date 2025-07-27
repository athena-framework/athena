require "../spec_helper"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe ADI::ServiceContainer::ProcessAliases, tags: "compiled" do
  it "errors if unable to determine the alias name" do
    assert_compile_time_error "Alias cannot be automatically determined for 'foo' (Foo). If the type includes multiple interfaces, provide the interface to alias as the first positional argument to `@[ADI::AsAlias]`.", <<-'CR'
      module SomeInterface; end
      module OtherInterface; end

      @[ADI::Register]
      @[ADI::AsAlias]
      class Foo
        include SomeInterface
        include OtherInterface
      end
    CR
  end

  it "allows explicit string alias name" do
    assert_compiles <<-'CR'
      @[ADI::Register]
      @[ADI::AsAlias("bar")]
      class Foo; end

      macro finished
        macro finished
          \{%
            raise "" unless ADI::ServiceContainer::ALIASES.keys == ["bar"]
            raise "" unless ADI::ServiceContainer::ALIASES["bar"]["id"] == "foo"
            raise "" unless ADI::ServiceContainer::ALIASES["bar"]["public"] == false
          %}
        end
      end
    CR
  end

  it "allows explicit const alias name" do
    assert_compiles <<-'CR'
      BAR = "bar"

      @[ADI::Register]
      @[ADI::AsAlias(BAR)]
      class Foo; end

      macro finished
        macro finished
          \{%
            raise "" unless ADI::ServiceContainer::ALIASES.keys == ["bar"]
            raise "" unless ADI::ServiceContainer::ALIASES["bar"]["id"] == "foo"
            raise "" unless ADI::ServiceContainer::ALIASES["bar"]["public"] == false
          %}
        end
      end
    CR
  end

  it "allows explicit TypeNode alias name" do
    assert_compiles <<-'CR'
      module SomeInterface; end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface, public: true)]
      class Foo
        include SomeInterface
      end

      macro finished
        macro finished
          \{%
            raise "" unless ADI::ServiceContainer::ALIASES.keys == [SomeInterface]
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface]["id"] == "foo"
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface]["public"] == true
          %}
        end
      end
    CR
  end

  it "uses included interface type as alias name if there is only 1" do
    assert_compiles <<-'CR'
      module SomeInterface; end

      @[ADI::Register]
      @[ADI::AsAlias]
      class Foo
        include SomeInterface
      end

      macro finished
        macro finished
          \{%
            raise "" unless ADI::ServiceContainer::ALIASES.keys == [SomeInterface]
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface]["id"] == "foo"
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface]["public"] == false
          %}
        end
      end
    CR
  end

  it "allows aliasing more than one interface" do
    assert_compiles <<-'CR'
      module SomeInterface; end
      module OtherInterface; end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface)]
      @[ADI::AsAlias(OtherInterface)]
      class Foo
        include SomeInterface
        include OtherInterface
      end

      macro finished
        macro finished
          \{%
            raise "" unless ADI::ServiceContainer::ALIASES.keys == [SomeInterface, OtherInterface]
          %}
        end
      end
    CR
  end
end
