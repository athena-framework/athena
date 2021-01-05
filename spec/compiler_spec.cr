require "./spec_helper"

describe Athena::Routing do
  describe "compiler errors" do
    it "action argument missing type restriction" do
      assert_error "compiler/missing_action_argument_type_restriction.cr", "Route action argument 'CompileController#action:id' must have a type restriction."
    end

    it "action missing return type" do
      assert_error "compiler/missing_action_return_type.cr", "Route action return type must be set for 'CompileController#action'."
    end

    it "class method action" do
      assert_error "compiler/class_method_action.cr", "Routes can only be defined as instance methods.  Did you mean 'CompileController#class_method'?"
    end

    it "when action does not have a path" do
      assert_error "compiler/missing_path.cr", "Route action 'CompileController#action' is annotated as a 'GET' route but is missing the path."
    end

    it "when a controller type is registered as a service but is not public" do
      assert_error "compiler/controller_service_not_public.cr", "Controller service 'CompileController' must be declared as public."
    end

    it "when action is defined with ARTA::Route, but does not specify the method" do
      assert_error "compiler/missing_route_method.cr", "CompileController#action' is missing the HTTP method.  It was not provided via the 'method' field."
    end

    describe ARTA::Prefix do
      it "when a parent type has the prefix annotation but is missing a value" do
        assert_error "compiler/parent_missing_prefix.cr", "Controller 'PrefixController' has the `Prefix` annotation but is missing the prefix."
      end

      it "when a type has the prefix annotation but is missing a value" do
        assert_error "compiler/missing_prefix.cr", "Controller 'CompileController' has the `Prefix` annotation but is missing the prefix."
      end
    end

    describe ARTA::ParamConverter do
      it "missing name" do
        assert_error "compiler/param_converter_missing_name.cr", "Route action 'CompileController#action' has an ARTA::ParamConverter annotation but is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field."
      end

      it "missing corresponding action argument" do
        assert_error "compiler/param_converter_missing_action_argument.cr", "Route action 'CompileController#action' has an ARTA::ParamConverter annotation but does not have a corresponding action argument for 'foo'."
      end

      it "missing converter argument" do
        assert_error "compiler/param_converter_missing_converter.cr", "Route action 'CompileController#action' has an ARTA::ParamConverter annotation but is missing the converter class.  It was not provided via the 'converter' field."
      end
    end

    describe ARTA::QueryParam do
      it "missing name" do
        assert_error "compiler/query_param_missing_name.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation but is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field."
      end

      it "missing corresponding action argument" do
        assert_error "compiler/query_param_missing_action_argument.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation but does not have a corresponding action argument for 'foo'."
      end

      it "disallows non nilable non strict and no default params" do
        assert_error "compiler/query_param_not_strict_not_nilable_no_default.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation with `strict: false` but the related action argument is not nilable nor has a default value."
      end

      describe "requirements" do
        describe "only allows `Assert` annotations as requirements (other than regex)" do
          it "with a single annotation" do
            assert_error "compiler/query_param_invalid_requirements_annotation.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation whose 'requirements' value is invalid.  Expected `Assert` annotation, got '@[ARTA::Get]'."
          end

          describe "in an array" do
            it "with a scalar value" do
              assert_error "compiler/query_param_invalid_requirements_array_value.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation whose 'requirements' array contains an invalid value.  Expected `Assert` annotation, got '1' at index 1."
            end

            it "with an annotation value" do
              assert_error "compiler/query_param_invalid_requirements_array_annotation.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation whose 'requirements' array contains an invalid value.  Expected `Assert` annotation, got '@[ARTA::Get]' at index 1."
            end
          end

          it "with a scalar requirements value" do
            assert_error "compiler/query_param_invalid_requirements_type.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation with an invalid 'requirements' type: 'StringLiteral'.  Only Regex, NamedTuple, or Array values are supported."
          end
        end
      end

      describe "converter" do
        it "disallows non NamedTuple and Paths" do
          assert_error "compiler/query_param_invalid_converter_type.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation with an invalid 'converter' type: 'StringLiteral'.  Only NamedTuples, or the converter class are supported."
        end

        it "disallows non ART::ParamConverterInterface types" do
          assert_error "compiler/query_param_invalid_converter_class.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation with an invalid 'converter' value.  Expected 'ART::ParamConverterInterface.class' got 'Athena::Routing::Controller'."
        end

        it "requires the name to be provided when using a NamedTuple" do
          assert_error "compiler/query_param_converter_missing_name.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::QueryParam annotation with an invalid 'converter'. The converter's name was not provided via the 'name' field."
        end
      end
    end

    # This is essentially the same as `ARTA::QueryParam`.
    # Just do a simple check to ensure its working as expected while doing most other assertions with `ARTA::QueryParam`.
    describe ARTA::RequestParam do
      it "missing name" do
        assert_error "compiler/request_param_missing_name.cr", "Route action 'CompileController#action' has an Athena::Routing::Annotations::RequestParam annotation but is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field."
      end
    end

    describe "route collision detection" do
      it "same path" do
        assert_error "compiler/conflicting_route.cr", "Route action OtherController#action2's path \"/some/path/:id\" conflicts with TestController#action1's path \"/some/path/:id\"."
      end

      it "same path different argument names" do
        assert_error "compiler/conflicting_route_different_argument_name.cr", "Route action OtherController#action2's path \"/user/:user_id\" conflicts with TestController#action1's path \"/user/:id\"."
      end

      it "same path and constraints" do
        assert_error "compiler/conflicting_route_constraints.cr", "Route action OtherController#action2's path \"/user/:id\" conflicts with TestController#action1's path \"/user/:id\"."
      end
    end
  end
end
