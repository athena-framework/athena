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
            raise "" unless ADI::ServiceContainer::ALIASES["bar"].size == 1
            raise "" unless ADI::ServiceContainer::ALIASES["bar"][0]["id"] == "foo"
            raise "" unless ADI::ServiceContainer::ALIASES["bar"][0]["public"] == false
            raise "" unless ADI::ServiceContainer::ALIASES["bar"][0]["name"].nil?
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
            raise "" unless ADI::ServiceContainer::ALIASES["bar"].size == 1
            raise "" unless ADI::ServiceContainer::ALIASES["bar"][0]["id"] == "foo"
            raise "" unless ADI::ServiceContainer::ALIASES["bar"][0]["public"] == false
            raise "" unless ADI::ServiceContainer::ALIASES["bar"][0]["name"].nil?
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
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface].size == 1
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][0]["id"] == "foo"
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][0]["public"] == true
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][0]["name"].nil?
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
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface].size == 1
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][0]["id"] == "foo"
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][0]["public"] == false
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][0]["name"].nil?
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
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface].size == 1
            raise "" unless ADI::ServiceContainer::ALIASES[OtherInterface].size == 1
          %}
        end
      end
    CR
  end

  it "allows named alias with type" do
    assert_compiles <<-'CR'
      module SomeInterface; end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface, name: "my_param")]
      class Foo
        include SomeInterface
      end

      macro finished
        macro finished
          \{%
            raise "" unless ADI::ServiceContainer::ALIASES.keys == [SomeInterface]
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface].size == 1
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][0]["id"] == "foo"
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][0]["name"].id == "my_param"
          %}
        end
      end
    CR
  end

  it "allows multiple named aliases for same type" do
    assert_compiles <<-'CR'
      module SomeInterface; end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface, name: "first")]
      class First
        include SomeInterface
      end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface, name: "second")]
      class Second
        include SomeInterface
      end

      macro finished
        macro finished
          \{%
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface].size == 2
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][0]["name"].id == "first"
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface][1]["name"].id == "second"
          %}
        end
      end
    CR
  end

  it "allows both named and type-only aliases for same type" do
    assert_compiles <<-'CR'
      module SomeInterface; end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface, name: "specific")]
      class Specific
        include SomeInterface
      end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface)]
      class Default
        include SomeInterface
      end

      macro finished
        macro finished
          \{%
            raise "" unless ADI::ServiceContainer::ALIASES[SomeInterface].size == 2
            named = ADI::ServiceContainer::ALIASES[SomeInterface].find { |a| !a["name"].nil? }
            type_only = ADI::ServiceContainer::ALIASES[SomeInterface].find { |a| a["name"].nil? }
            raise "" unless named["id"] == "specific"
            raise "" unless type_only["id"] == "default"
          %}
        end
      end
    CR
  end

  it "errors on duplicate type+name combination" do
    assert_compile_time_error "Duplicate alias for type 'SomeInterface' with name 'my_param'", <<-'CR'
      module SomeInterface; end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface, name: "my_param")]
      class Foo
        include SomeInterface
      end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface, name: "my_param")]
      class Bar
        include SomeInterface
      end
    CR
  end

  it "errors on duplicate type-only alias" do
    assert_compile_time_error "Duplicate alias for type 'SomeInterface'. A type-only alias", <<-'CR'
      module SomeInterface; end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface)]
      class Foo
        include SomeInterface
      end

      @[ADI::Register]
      @[ADI::AsAlias(SomeInterface)]
      class Bar
        include SomeInterface
      end
    CR
  end
end
