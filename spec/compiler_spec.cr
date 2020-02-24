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

    pending "query parameter annotation but missing action argument" do
      assert_error "compiler/query_param_missing_name.cr", "Route action 'CompileController#action's QueryParam annotation is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field."
    end

    pending "param converter annotation but missing action argument" do
      assert_error "compiler/param_converter_missing_name.cr", "Route action 'CompileController#action's ParamConverter annotation is missing the argument's name.  It was not provided as the first positional argument nor via the 'param' field."
    end

    pending "when action argument count does not equal expected count" do
      assert_error "compiler/argument_count_mismatch.cr", "Route action 'CompileController#action' doesn't have the correct number of arguments.  Expected 1 but got 0."
    end

    it "when action does not have a path" do
      assert_error "compiler/missing_path.cr", "Route action 'CompileController#action' is annotated as a 'GET' route but is missing the path."
    end

    it "when a parent type has the prefix annotation but is missing a value" do
      assert_error "compiler/parent_missing_prefix.cr", "Controller 'PrefixController' has the `Prefix` annotation but is missing the prefix."
    end

    it "when a type has the prefix annotation but is missing a value" do
      assert_error "compiler/missing_prefix.cr", "Controller 'CompileController' has the `Prefix` annotation but is missing the prefix."
    end
  end
end
