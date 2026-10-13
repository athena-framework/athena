require "../spec_helper"

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: %(require "../spec_helper.cr"), postamble: "ADI::ServiceContainer.new"
end

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: %(require "../spec_helper.cr"), postamble: "ADI::ServiceContainer.new"
end

# Defines a bundle whose extension aliases `SomeInterface`, both type-only and named, along with a service injecting both aliases.
private BUNDLE_ALIASES_PREAMBLE = <<-'CR'
  require "../spec_helper.cr"

  module SomeInterface; end

  class BundleService
    include SomeInterface
  end

  class BundleNamedService
    include SomeInterface
  end

  @[ADI::Bundle("alias_bundle")]
  struct AliasBundle < ADI::AbstractBundle
    PASSES = [] of _

    module Schema
      include ADI::Extension::Schema
    end

    module Extension
      macro included
        macro finished
          {% verbatim do %}
            {%
              SERVICE_HASH["bundle_service"] = {class: BundleService}
              SERVICE_HASH["bundle_named_service"] = {class: BundleNamedService}

              ALIASES[SomeInterface] = [
                {id: "bundle_service", public: false},
                {id: "bundle_named_service", public: false, name: "named_param"},
              ]
            %}
          {% end %}
        end
      end
    end
  end

  ADI.register_bundle AliasBundle

  @[ADI::Register(public: true)]
  class SomeInterfaceConsumer
    def initialize(@some_param : SomeInterface, @named_param : SomeInterface); end
  end
  CR

private def assert_compiles_with_bundle_aliases(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: BUNDLE_ALIASES_PREAMBLE, postamble: "ADI::ServiceContainer.new"
end

private def assert_compile_time_error_with_bundle_aliases(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: BUNDLE_ALIASES_PREAMBLE, postamble: "ADI::ServiceContainer.new"
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
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES.keys == ["bar"] }}, "Expected alias keys to be [bar]")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES["bar"].size == 1 }}, "Expected bar alias size to be 1")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES["bar"][0]["id"] == "foo" }}, "Expected bar alias id to be foo")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES["bar"][0]["public"] == false }}, "Expected bar alias public to be false")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES["bar"][0]["name"].nil? }}, "Expected bar alias name to be nil")
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
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES.keys == ["bar"] }}, "Expected alias keys to be [bar]")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES["bar"].size == 1 }}, "Expected bar alias size to be 1")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES["bar"][0]["id"] == "foo" }}, "Expected bar alias id to be foo")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES["bar"][0]["public"] == false }}, "Expected bar alias public to be false")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES["bar"][0]["name"].nil? }}, "Expected bar alias name to be nil")
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
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES.keys == [SomeInterface] }}, "Expected alias keys to be [SomeInterface]")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface].size == 1 }}, "Expected SomeInterface alias size to be 1")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][0]["id"] == "foo" }}, "Expected SomeInterface alias id to be foo")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][0]["public"] == true }}, "Expected SomeInterface alias public to be true")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][0]["name"].nil? }}, "Expected SomeInterface alias name to be nil")
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
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES.keys == [SomeInterface] }}, "Expected alias keys to be [SomeInterface]")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface].size == 1 }}, "Expected SomeInterface alias size to be 1")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][0]["id"] == "foo" }}, "Expected SomeInterface alias id to be foo")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][0]["public"] == false }}, "Expected SomeInterface alias public to be false")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][0]["name"].nil? }}, "Expected SomeInterface alias name to be nil")
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
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES.keys == [SomeInterface, OtherInterface] }}, "Expected alias keys to be [SomeInterface, OtherInterface]")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface].size == 1 }}, "Expected SomeInterface alias size to be 1")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[OtherInterface].size == 1 }}, "Expected OtherInterface alias size to be 1")
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
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES.keys == [SomeInterface] }}, "Expected alias keys to be [SomeInterface]")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface].size == 1 }}, "Expected SomeInterface alias size to be 1")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][0]["id"] == "foo" }}, "Expected SomeInterface alias id to be foo")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][0]["name"].id == "my_param" }}, "Expected SomeInterface alias name to be my_param")
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
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface].size == 2 }}, "Expected SomeInterface alias size to be 2")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][0]["name"].id == "first" }}, "Expected SomeInterface alias[0] name to be first")
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface][1]["name"].id == "second" }}, "Expected SomeInterface alias[1] name to be second")
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
          ASPEC.compile_time_assert(\{{ ADI::ServiceContainer::ALIASES[SomeInterface].size == 2 }}, "Expected SomeInterface alias size to be 2")
          \{%
            named = ADI::ServiceContainer::ALIASES[SomeInterface].find { |a| !a["name"].nil? }
            type_only = ADI::ServiceContainer::ALIASES[SomeInterface].find { |a| a["name"].nil? }
          %}
          ASPEC.compile_time_assert(\{{ named["id"] == "specific" }}, "Expected named alias id to be specific")
          ASPEC.compile_time_assert(\{{ type_only["id"] == "default" }}, "Expected type-only alias id to be default")
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

  describe "with aliases defined by a bundle extension" do
    it "allows a type-only alias to replace the type-only alias of the extension" do
      assert_compiles_with_bundle_aliases <<-'CR'
        @[ADI::Register]
        @[ADI::AsAlias(SomeInterface)]
        class AppService
          include SomeInterface
        end

        macro finished
          macro finished
            \{%
              aliases = ADI::ServiceContainer::ALIASES[SomeInterface]
              named = aliases.find { |a| !a["name"].nil? }
              type_only = aliases.find { |a| a["name"].nil? }
              consumer_parameters = ADI::ServiceContainer::SERVICE_HASH["some_interface_consumer"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ aliases.size == 2 }}, "Expected SomeInterface alias size to be 2")
            ASPEC.compile_time_assert(\{{ type_only["id"] == "app_service" }}, "Expected type-only alias id to be app_service")
            ASPEC.compile_time_assert(\{{ named["id"] == "bundle_named_service" }}, "Expected named alias id to be bundle_named_service")
            ASPEC.compile_time_assert(\{{ consumer_parameters["some_param"]["value"].stringify == "app_service" }}, "Expected some_param to be app_service")
            ASPEC.compile_time_assert(\{{ consumer_parameters["named_param"]["value"].stringify == "bundle_named_service" }}, "Expected named_param to be bundle_named_service")
          end
        end
      CR
    end

    it "allows a named alias to replace the alias of the extension with the same name" do
      assert_compiles_with_bundle_aliases <<-'CR'
        @[ADI::Register]
        @[ADI::AsAlias(SomeInterface, name: "named_param")]
        class AppService
          include SomeInterface
        end

        macro finished
          macro finished
            \{%
              aliases = ADI::ServiceContainer::ALIASES[SomeInterface]
              named = aliases.find { |a| !a["name"].nil? }
              type_only = aliases.find { |a| a["name"].nil? }
              consumer_parameters = ADI::ServiceContainer::SERVICE_HASH["some_interface_consumer"]["parameters"]
            %}
            ASPEC.compile_time_assert(\{{ aliases.size == 2 }}, "Expected SomeInterface alias size to be 2")
            ASPEC.compile_time_assert(\{{ named["id"] == "app_service" }}, "Expected named alias id to be app_service")
            ASPEC.compile_time_assert(\{{ type_only["id"] == "bundle_service" }}, "Expected type-only alias id to be bundle_service")
            ASPEC.compile_time_assert(\{{ consumer_parameters["some_param"]["value"].stringify == "bundle_service" }}, "Expected some_param to be bundle_service")
            ASPEC.compile_time_assert(\{{ consumer_parameters["named_param"]["value"].stringify == "app_service" }}, "Expected named_param to be app_service")
          end
        end
      CR
    end

    it "errors if more than one annotation replaces the same alias of the extension" do
      assert_compile_time_error_with_bundle_aliases "Duplicate alias for type 'SomeInterface'. A type-only alias", <<-'CR'
        @[ADI::Register]
        @[ADI::AsAlias(SomeInterface)]
        class AppService
          include SomeInterface
        end

        @[ADI::Register]
        @[ADI::AsAlias(SomeInterface)]
        class OtherAppService
          include SomeInterface
        end
      CR
    end
  end
end
