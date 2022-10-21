require "./spec_helper"

describe Athena::DependencyInjection::ServiceContainer do
  describe "registration" do
    describe "that resolves to a single type" do
      it "should inject that type" do
        ADI.container.single_client.service.should be_a SingleService
      end
    end

    describe "that is namespaced" do
      it "correctly resolves the service" do
        ADI.container.namespace_client.service.should be_a MyApp::Models::Foo
      end
    end

    describe "that resolves to more than one type" do
      describe "with an alias" do
        it "should inject the aliased service based on interface" do
          ADI.container.transformer_alias_client.service.should be_a ReverseTransformer
        end

        it "allows overriding aliases" do
          ADI.container.get(ConverterInterface).should be_a ConverterTwo
        end

        it "converts the aliased service into a proxy if desired" do
          service = ADI.container.proxy_transformer_alias_client
          service.service_one.should be_a ADI::Proxy(TransformerInterface)
          service.service_one.instance.should be_a ReverseTransformer
        end
      end

      describe "variable name matches a service" do
        it "should inject the service whose ID matches the name of the constructor variable" do
          ADI.container.transformer_alias_name_client.service.should be_a ShoutTransformer
        end

        it "converts the aliased service into a proxy if desired" do
          service = ADI.container.proxy_transformer_alias_client
          service.shout_transformer.should be_a ADI::Proxy(ShoutTransformer)
          service.shout_transformer.instance.should be_a ShoutTransformer
        end
      end
    end

    describe "where a dependency is optional" do
      describe "and does not exist" do
        describe "without a default value" do
          it "should inject `nil`" do
            ADI.container.optional_client.service_missing.should be_nil
          end
        end

        describe "with a default value" do
          it "should inject the default" do
            ADI.container.optional_client.service_default.should eq 12
          end
        end
      end

      describe "and does exist" do
        it "should inject that service" do
          ADI.container.optional_client.service_existing.should be_a OptionalExistingService
        end
      end
    end

    describe "with a generic service" do
      it "correctly initializes the service with the given generic arguments" do
        ADI.container.int_service.type.should eq({Int32, Bool})
        ADI.container.float_service.type.should eq({Float64, Bool})
      end
    end

    describe "with scalar arguments" do
      it "passes them to the constructor" do
        service = ADI.container.scalar_client
        service.value.should eq 22
        service.array.should eq [1, 2, 3]
        service.named_tuple.should eq({id: 17, active: true})
      end
    end

    describe "with explicit array of services" do
      it "passes them to the constructor" do
        services = ADI.container.array_client.services
        services[0].should be_a ArrayService
        services[1].should be_a API::Models::NestedArrayService
      end

      it "also allows the service to still have defaults after the array argument" do
        service = ADI.container.array_value_default_client
        service.values.size.should eq 3
        service.status.should eq Status::Active
      end
    end

    describe "that is tag based" do
      it "injects all services with that tag, ordering based on priority" do
        services = ADI.container.partner_client.services
        services[0].id.should eq 3
        services[1].id.should eq 1
        services[2].id.should eq 2
        services[3].id.should eq 4
      end

      it "also allows the service to still have defaults after the tagged services argument" do
        service = ADI.container.partner_named_default_client
        service.services.size.should eq 4
        service.status.should eq Status::Active
      end

      it "converts each tagged service into a proxy" do
        services = ADI.container.proxy_tag_client.services
        services[0].id.should eq 3
        services[1].id.should eq 1
        services[2].id.should eq 2
        services[3].id.should eq 4
      end
    end

    describe "with bound values" do
      it "without types" do
        service = ADI.container.binding_client
        service.override_binding.should eq 2
        service.api_key.should eq "123ABC"
        service.config.should eq({id: 12_i64, active: true})
        service.odd_values.should eq [ValueService.new(1), ValueService.new(3)]
        service.prime_values.should eq [ValueService.new(2), ValueService.new(3)]
      end

      it "with types" do
        ADI.container.int_arr_client.values.should eq [1, 2, 3]
        ADI.container.str_arr_client.values.should eq ["one", "two", "three"]
        ADI.container.mixed_untyped_binding_client.mixed_type_value.should eq 1
        ADI.container.mixed_typed_binding_client.mixed_type_value.should be_true
        ADI.container.mixed_both_binding_client.mixed_type_value.should be_true

        service = ADI.container.typed_binding_client
        service.debug.should eq 0
        service.typed_value.should eq "bar"
      end

      it "allows the service to still have defaults after the bound array argument" do
        service = ADI.container.int_arr_default_client
        service.values.size.should eq 3
        service.status.should eq Status::Active
      end

      it "allows the service to still have defaults after the bound array argument" do
        service = ADI.container.prime_arr_default_client
        service.prime_values.size.should eq 2
        service.status.should eq Status::Active
      end

      it "allows converting bound tagged services into a proxy" do
        service = ADI.container.proxy_bound_client
        service.prime_values.should eq [ValueService.new(2), ValueService.new(3)]
        service.typed_prime_values.should eq [ValueService.new(2), ValueService.new(3)]
      end
    end

    describe "with auto configured services" do
      it "supports adding tags" do
        services = ADI.container.config_client.configs
        services.size.should eq 2
        services[0].should be_a ConfigOne
        services[1].should be_a ConfigTwo
      end

      it "supports changing the visibility of a service" do
        ADI::ServiceContainer.new.config_four.should be_a ConfigFour
      end
    end

    describe "with factory based services" do
      it "supports passing a tuple" do
        ADI::ServiceContainer.new.factory_tuple.value.should eq 30
      end

      it "supports passing the string method name" do
        ADI::ServiceContainer.new.factory_string.value.should eq 20
      end

      it "supports auto resolving factory method service depednecies" do
        ADI::ServiceContainer.new.factory_service.value.should eq 10
      end

      it "with the ADI::Inject annotation" do
        ADI::ServiceContainer.new.pseudo_factory.value.should eq 100
      end
    end

    describe "with service proxies" do
      it "delays instantiation until the proxy is used" do
        service = ADI.container.service_one
        ServiceThree.instantiated?.should be_false
        service.test
        ServiceThree.instantiated?.should be_false
        service.run.should eq 123
        ServiceThree.instantiated?.should be_true
      end

      it "exposes the service ID and type of the proxied service" do
        service = ADI.container.service_one
        service.service_two_extra.service_id.should eq "service_two"
        service.service_two_extra.service_type.should eq ServiceTwo
        service.service_two_extra.instantiated?.should be_false
        service.service_two_extra.value.should eq 123
        service.service_two_extra.instantiated?.should be_true

        service.namespaced_service.service_id.should eq "some_namespace_service"
        service.namespaced_service.service_type.should eq Some::Namespace::Service
      end
    end

    it "with parameters" do
      service = ADI::ServiceContainer.new.parameter_client
      service.username.should eq "USER"
      service.password.should eq "PASS"
      service.credentials.should eq ["USER", "HOST"]
    end

    it "with configuration" do
      service = ADI::ServiceContainer.new.configuration_client
      service.some_config.value.should eq 123
      service.nilable_config.should be_nil
      service.nested_config.value.should eq 456
    end

    it "when the constructor arg is not typed, but has a default" do
      ADI::ServiceContainer.new.some_un_typed_service.service.id.should eq 1234
    end
  end

  describe "compiler passes" do
    describe "pre argument" do
      it "has access to registered services, but not arguments" do
        BeforeArgsPassClient.factory_string_value.should eq 10
        BeforeArgsPassClient.factory_service_argument_count.should be_nil
      end
    end

    describe "post argument" do
      it "has access to service arguments" do
        AfterArgsPassClient.scalar_client_default_value.should eq 22
        AfterArgsPassClient.scalar_client_arg_count.should eq 3
        AfterArgsPassClient.partner_client_service_ids.should eq ["google", "facebook", "yahoo", "microsoft"]
      end
    end
  end
end
