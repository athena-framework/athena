require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

module AliasInterface; end

@[ADI::Register]
record AliasOne do
  include AliasInterface
end

@[ADI::Register(alias: AliasInterface)]
record AliasTwo do
  include AliasInterface
end

@[ADI::Register(public: true)]
record AliasService, a_service : AliasInterface

describe ADI::ServiceContainer::RegisterServices do
  describe "compiler errors", tags: "compiler" do
    it "errors if a service has multiple ADI::Register annotations but not all of them have a name" do
      assert_error "Failed to register services for 'Foo'. Services based on this type must each explicitly provide a name.", <<-CR
        @[ADI::Register(name: "one")]
        @[ADI::Register]
        record Foo
      CR
    end
  end

  it "supports aliasing a specific service for an interface" do
    ADI.container.alias_service.a_service.should be_a AliasTwo
  end
end
