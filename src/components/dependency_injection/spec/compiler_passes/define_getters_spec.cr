require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
  CR
end

module PublicStringAliasInterface; end

@[ADI::Register]
@[ADI::AsAlias("bar_string_alias", public: true)]
class PublicStringAlias
  include PublicStringAliasInterface
end

module TypedGetterAliasInterface; end

@[ADI::Register]
@[ADI::AsAlias(public: true)]
class TypedGetterAlias
  include TypedGetterAliasInterface
end

describe ADI::ServiceContainer::DefineGetters, tags: "compiled" do
  describe "compiler errors" do
    describe "aliases" do
      it "does not expose named getter for non-public string aliases" do
        assert_error "undefined method 'bar' for Athena::DependencyInjection::ServiceContainer", <<-'CR'
          module SomeInterface; end

          @[ADI::Register]
          @[ADI::AsAlias("bar")]
          class Foo
            include SomeInterface
          end

          ADI.container.bar
        CR
      end

      it "does not expose typed getter for non-public typed aliases" do
        assert_error "undefined method 'get' for Athena::DependencyInjection::ServiceContainer", <<-'CR'
          module SomeInterface; end

          @[ADI::Register]
          @[ADI::AsAlias]
          class Foo
            include SomeInterface
          end

          ADI.container.get SomeInterface
        CR
      end
    end
  end

  describe "aliases" do
    it "exposes named getter for public string alias" do
      ADI.container.bar_string_alias.should be_a PublicStringAlias
    end

    it "exposes typed getter for public typed alias" do
      ADI.container.get(TypedGetterAliasInterface).should be_a TypedGetterAlias
    end
  end
end
