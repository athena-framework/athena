require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
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

module ArrayServiceInterface; end

@[ADI::Register]
@[ADI::AsAlias]
struct ArrayOne
  include ArrayServiceInterface
end

@[ADI::Register]
@[ADI::AsAlias]
struct ArrayTwo
  include ArrayServiceInterface
end

@[ADI::Register]
@[ADI::AsAlias]
struct ArrayThree
  include ArrayServiceInterface
end

@[ADI::Register(_services: ["@array_one", "@array_three"], public: true)]
record ImplicitArrayClient, services : Array(ArrayServiceInterface)

@[ADI::Register(public: true)]
record ExplicitArrayClient, services : Array(ArrayServiceInterface) = [] of ArrayServiceInterface

describe ADI::ServiceContainer::DefineGetters, tags: "compiled" do
  describe "compiler errors" do
    describe "aliases" do
      it "does not expose named getter for non-public string aliases" do
        assert_compile_time_error "undefined method 'bar' for Athena::DependencyInjection::ServiceContainer", <<-'CR'
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
        assert_compile_time_error "undefined method 'get' for Athena::DependencyInjection::ServiceContainer", <<-'CR'
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

    it "implicitly applies `of Type` restrictions to array values" do
      ADI.container.implicit_array_client.services.should eq [ArrayOne.new, ArrayThree.new]
    end

    it "does not apply `of Type` restriction to values that already explicitly have one" do
      ADI.container.explicit_array_client.services.should be_empty
    end
  end
end
