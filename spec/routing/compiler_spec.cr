require "./routing_spec_helper"

describe Athena::Routing do
  describe "compiler errors" do
    it "action argument missing type restriction" do
      assert_error "routing/compiler/missing_action_argument_type_restriction.cr", "Route action argument 'CompileController#action:id' must have a type restriction."
    end

    it "action missing return type" do
      assert_error "routing/compiler/missing_action_return_type.cr", "Route action return type must be set for 'CompileController#action'."
    end

    it "class method action" do
      assert_error "routing/compiler/class_method_action.cr", "Routes can only be defined as instance methods.  Did you mean 'CompileController#class_method'?"
    end

    it "query parameter annotation but missing action argument" do
      assert_error "routing/compiler/query_param_missing_name.cr", "Route action 'CompileController#action's QueryParam annotation is missing required field: 'name'."
    end

    it "when action argument count does not equal expected count" do
      assert_error "routing/compiler/argument_count_mismatch.cr", "Route action 'CompileController#action' doesn't have the correct number of arguments.  Expected 1 but got 0."
    end
  end
end
