require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
  CR
end

describe ADI::ServiceContainer::RemoveUnusedServices, tags: "compiled" do
  it "removes private services with zero references" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      @[ADI::Register]
      class UnusedService
      end

      @[ADI::Register(public: true)]
      class UsedService
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          \{%
            # Unused private service should be removed
            raise "UnusedService should be removed" unless ADI::ServiceContainer::SERVICE_HASH["unused_service"].nil?

            # Used public service should still exist
            raise "UsedService should exist" if ADI::ServiceContainer::SERVICE_HASH["used_service"].nil?
          %}
        end
      end
    CR
  end

  it "does not remove private services that are referenced" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      @[ADI::Register]
      class ReferencedService
        def value
          42
        end
      end

      @[ADI::Register(public: true)]
      class ClientService
        def initialize(@dep : ReferencedService)
        end
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          \{%
            # Referenced private service should NOT be removed
            raise "ReferencedService should exist" if ADI::ServiceContainer::SERVICE_HASH["referenced_service"].nil?
          %}
        end
      end
    CR
  end

  it "does not remove services that are targets of public aliases" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      module SomeInterface; end

      @[ADI::Register]
      @[ADI::AsAlias("my_alias", public: true)]
      class AliasedService
        include SomeInterface
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          \{%
            # Service with public alias should NOT be removed
            raise "AliasedService should exist" if ADI::ServiceContainer::SERVICE_HASH["aliased_service"].nil?
          %}
        end
      end
    CR
  end
end
