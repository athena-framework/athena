require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
  CR
end

describe ADI::ServiceContainer::InlineServiceDefinitions, tags: "compiled" do
  it "inlines single-use private services" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      @[ADI::Register]
      class InlinedDep
        def value
          42
        end
      end

      @[ADI::Register(public: true)]
      class ClientService
        def initialize(@dep : InlinedDep)
        end

        def get_value
          @dep.value
        end
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          \{%
            # Single-use private service should be marked for inlining
            dep = ADI::ServiceContainer::SERVICE_HASH["inlined_dep"]
            raise "InlinedDep should be marked as inlined" unless dep && dep["inlined"]
          %}
        end
      end
    CR
  end

  it "does not inline services that are targets of public aliases" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      module SomeInterface; end

      @[ADI::Register]
      @[ADI::AsAlias("my_alias", public: true)]
      class AliasTargetService
        include SomeInterface
      end

      @[ADI::Register(public: true)]
      class ClientService
        def initialize(@dep : AliasTargetService)
        end
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          \{%
            # Service with public alias should NOT be inlined
            dep = ADI::ServiceContainer::SERVICE_HASH["alias_target_service"]
            raise "AliasTargetService should exist and not be inlined" if dep.nil? || dep["inlined"]
          %}
        end
      end
    CR
  end

  it "does not inline services referenced via Proxy" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      @[ADI::Register]
      class ProxyTargetService
        def value
          42
        end
      end

      @[ADI::Register(public: true)]
      class ClientService
        def initialize(@proxy : ADI::Proxy(ProxyTargetService))
        end
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          \{%
            # Proxy target should NOT be inlined (needs getter for proc reference)
            dep = ADI::ServiceContainer::SERVICE_HASH["proxy_target_service"]
            raise "ProxyTargetService should exist and not be inlined: #{dep}" if dep.nil? || dep["inlined"]
          %}
        end
      end
    CR
  end

  it "does not inline public services" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      @[ADI::Register(public: true)]
      class PublicService
      end

      @[ADI::Register(public: true)]
      class ClientService
        def initialize(@dep : PublicService)
        end
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          \{%
            # Public service should NOT be inlined
            dep = ADI::ServiceContainer::SERVICE_HASH["public_service"]
            raise "PublicService should exist and not be inlined" if dep.nil? || dep["inlined"]
          %}
        end
      end
    CR
  end

  it "does not inline services with multiple references" do
    ASPEC::Methods.assert_compiles <<-'CR'
      require "../spec_helper.cr"

      @[ADI::Register]
      class MultiRefService
      end

      @[ADI::Register(public: true)]
      class Client1
        def initialize(@dep : MultiRefService)
        end
      end

      @[ADI::Register(public: true)]
      class Client2
        def initialize(@dep : MultiRefService)
        end
      end

      ADI::ServiceContainer.new

      macro finished
        macro finished
          \{%
            # Service with multiple references should NOT be inlined
            dep = ADI::ServiceContainer::SERVICE_HASH["multi_ref_service"]
            raise "MultiRefService should exist and not be inlined" if dep.nil? || dep["inlined"]
          %}
        end
      end
    CR
  end
end
