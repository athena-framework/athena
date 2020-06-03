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

    describe ART::Prefix do
      it "when a parent type has the prefix annotation but is missing a value" do
        assert_error "compiler/parent_missing_prefix.cr", "Controller 'PrefixController' has the `Prefix` annotation but is missing the prefix."
      end

      it "when a type has the prefix annotation but is missing a value" do
        assert_error "compiler/missing_prefix.cr", "Controller 'CompileController' has the `Prefix` annotation but is missing the prefix."
      end
    end

    describe ART::ParamConverter do
      it "missing name" do
        assert_error "compiler/param_converter_missing_name.cr", "Route action 'CompileController#action' has an ART::ParamConverter annotation but is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field."
      end

      it "missing corresponding action argument" do
        assert_error "compiler/param_converter_missing_action_argument.cr", "Route action 'CompileController#action' has an ART::ParamConverter annotation but does not have a corresponding action argument for 'foo'."
      end

      it "missing converter argument" do
        assert_error "compiler/param_converter_missing_converter.cr", "Route action 'CompileController#action' has an ART::ParamConverter annotation but is missing the converter class.  It was not provided via the 'converter' field."
      end
    end

    describe ART::QueryParam do
      it "missing name" do
        assert_error "compiler/query_param_missing_name.cr", "Route action 'CompileController#action' has an ART::QueryParam annotation but is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field."
      end

      it "missing corresponding action argument" do
        assert_error "compiler/query_param_missing_action_argument.cr", "Route action 'CompileController#action' has an ART::QueryParam annotation but does not have a corresponding action argument for 'foo'."
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
