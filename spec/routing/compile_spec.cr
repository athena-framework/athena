require "./routing_spec_helper"

describe Athena::Routing do
  describe "With missing" do
    describe "action parameters" do
      context "query" do
        describe "with no action parameters" do
          it "should not compile" do
            assert_error "routing/compiler/parameters/action/no_action_one_query.cr", "'bar' is defined in CompileController.no_action_one_query path/query parameters but is missing from action arguments."
          end
        end

        describe "with one action parameter" do
          it "should not compile" do
            assert_error "routing/compiler/parameters/action/one_action_two_query.cr", "'bar' is defined in CompileController.one_action_two_query path/query parameters but is missing from action arguments."
          end
        end

        describe "with *_id action parameter and non *_id query" do
          it "should not compile" do
            assert_error "routing/compiler/parameters/action/one_action_id_one_query.cr", "'num' is defined in CompileController.one_action_id_one_query path/query parameters but is missing from action arguments."
          end
        end
      end

      context "path parameters" do
        describe "with no action parameters" do
          it "should not compile" do
            assert_error "routing/compiler/parameters/action/no_action_one_path.cr", "'value' is defined in CompileController.no_action_one_path path/query parameters but is missing from action arguments."
          end
        end

        describe "with one action parameter" do
          it "should not compile" do
            assert_error "routing/compiler/parameters/action/one_action_two_path.cr", "'bar' is defined in CompileController.one_action_two_path path/query parameters but is missing from action arguments."
          end
        end

        describe "with *_id action parameter and non *_id path" do
          it "should not compile" do
            assert_error "routing/compiler/parameters/action/one_action_id_one_path.cr", "'num' is defined in CompileController.one_action_id_one_path path/query parameters but is missing from action arguments."
          end
        end
      end

      context "path + query parameters" do
        describe "with missing query" do
          it "should not compile" do
            assert_error "routing/compiler/parameters/action/one_action_one_query_one_path_query.cr", "'bar' is defined in CompileController.one_action_one_query_one_path_query path/query parameters but is missing from action arguments."
          end
        end

        describe "with missing path" do
          it "should not compile" do
            assert_error "routing/compiler/parameters/action/one_action_one_query_one_path_path.cr", "'bar' is defined in CompileController.one_action_one_query_one_path_path path/query parameters but is missing from action arguments."
          end
        end
      end
    end

    describe "query parameters" do
      describe "with one action parameter" do
        it "should not compile" do
          assert_error "routing/compiler/parameters/query/one_action_no_query.cr", "'foo' is defined in CompileController.one_action_no_query action arguments but is missing from path/query parameters."
        end
      end

      describe "with two action parameters" do
        it "should not compile" do
          assert_error "routing/compiler/parameters/query/two_action_one_query.cr", "'bar' is defined in CompileController.two_action_one_query action arguments but is missing from path/query parameters."
        end
      end
    end

    describe "path parameters" do
      describe "with one action parameter" do
        it "should not compile" do
          assert_error "routing/compiler/parameters/path/one_action_no_path.cr", "'foo' is defined in CompileController.one_action_no_path action arguments but is missing from path/query parameters."
        end
      end

      describe "with two action parameters" do
        it "should not compile" do
          assert_error "routing/compiler/parameters/path/two_action_one_path.cr", "'bar' is defined in CompileController.two_action_one_path action arguments but is missing from path/query parameters."
        end
      end
    end
  end

  describe "route actions" do
    describe "that is an instance method action" do
      it "should not compile" do
        assert_error "routing/compiler/actions/instance_method_action.cr", "Routes can only be defined on class methods.  Did you mean 'self.instance_method'?"
      end
    end

    describe "without a return type" do
      it "should not compile" do
        assert_error "routing/compiler/actions/no_return_type.cr", "Route action return type must be set for 'CompileController.no_return_type'"
      end
    end
  end

  describe "param converters" do
    describe "with a missing param field" do
      it "should not compile" do
        assert_error "routing/compiler/converters/no_param.cr", "CompileController.no_param ParamConverter annotation is missing a required field.  Must specifiy `param`, `type`, and `converter`."
      end
    end

    describe "with a missing type field" do
      it "should not compile" do
        assert_error "routing/compiler/converters/no_type.cr", "CompileController.no_type ParamConverter annotation is missing a required field.  Must specifiy `param`, `type`, and `converter`."
      end
    end

    describe "with a missing converter field" do
      it "should not compile" do
        assert_error "routing/compiler/converters/no_converter.cr", "CompileController.no_converter ParamConverter annotation is missing a required field.  Must specifiy `param`, `type`, and `converter`."
      end
    end

    context "Exists" do
      describe "that does not implement a .find method" do
        it "should not compile" do
          assert_error "routing/compiler/converters/exists/no_find.cr", "NoFind must implement a `self.find(id)` method to use the Exists converter."
        end
      end

      describe "that does not have the pk_type field" do
        it "should not compile" do
          assert_error "routing/compiler/converters/exists/no_pk_type.cr", "CompileController.no_pk_type Exists converter requires a `pk_type` to be defined."
        end
      end
    end

    context "FormData" do
      describe "that does not implement a .from_form_data method" do
        it "should not compile" do
          assert_error "routing/compiler/converters/form_data/no_from_form_data.cr", "NoFormData must implement a `self.from_form_data(form_data : HTTP::Params) : self` method to use the FormData converter."
        end
      end
    end
  end
end
