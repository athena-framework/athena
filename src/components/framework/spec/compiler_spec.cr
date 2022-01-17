require "./spec_helper"

private def assert_error(message : String | Bool, code : String, *, line : Int32 = __LINE__) : Nil
  input = IO::Memory.new <<-CR
    require "./spec_helper.cr"
    #{code}
    ATH.run
  CR

  buffer = IO::Memory.new
  result = Process.run("crystal", ["run", "--no-color", "--no-codegen", "--stdin-filename", "#{__DIR__}/test.cr"], input: input.rewind, output: buffer, error: buffer)

  case message
  in false
    fail buffer.to_s unless result.success?
  in true
    raise ArgumentError.new "'message' cannot be 'true'."
  in String
    fail buffer.to_s if result.success?
    buffer.to_s.should contain(message), line: line
    buffer.close
  end
end

describe Athena::Framework do
  describe "compiler errors", tags: "compiler" do
    it "action argument missing type restriction" do
      assert_error "Route action argument 'CompileController#action:id' must have a type restriction.", <<-CODE
        class CompileController < ATH::Controller
          @[ARTA::Get(path: "/:id")]
          def action(id) : Int32
            123
          end
        end
      CODE
    end

    it "action missing return type" do
      assert_error "Route action return type must be set for 'CompileController#action'.", <<-CODE
        class CompileController < ATH::Controller
          @[ARTA::Get(path: "/")]
          def action
            123
          end
        end
      CODE
    end

    it "class method action" do
      assert_error "Routes can only be defined as instance methods. Did you mean 'CompileController#class_method'?", <<-CODE
        class CompileController < ATH::Controller
          @[ARTA::Get(path: "/")]
          def self.class_method : Int32
            123
          end
        end
      CODE
    end

    it "when action does not have a path" do
      assert_error "Route action 'CompileController#action' is missing its path.", <<-CODE
        class CompileController < ATH::Controller
          @[ARTA::Get]
          def action : Int32
            123
          end
        end
      CODE
    end

    it "when a controller type is registered as a service but is not public" do
      assert_error "Controller service 'CompileController' must be declared as public.", <<-CODE
        @[ADI::Register]
        class CompileController < ATH::Controller
          @[ARTA::Get(path: "/")]
          def action : String
            "foo"
          end
        end
      CODE
    end

    describe "when a controller action is mistakenly overridden" do
      it "within the same controller" do
        assert_error "A controller action named '#action' already exists within 'CompileController'.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/foo")]
            def action : String
              "foo"
            end

            @[ARTA::Get(path: "/bar")]
            def action : String
              "bar"
            end
          end
        CODE
      end

      it "within a different controller" do
        assert_error false, <<-CODE
          class ExampleController < ATH::Controller
            @[ARTA::Get(path: "/foo")]
            def action : String
              "foo"
            end
          end

          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/bar")]
            def action : String
              "bar"
            end
          end
        CODE
      end
    end

    describe ARTA::Route do
      it "when there is a prefix for a controller action with a locale that does not have a route" do
        assert_error "Route action 'CompileController#action' is missing paths for locale(s) 'de'.", <<-CODE
          @[ARTA::Route(path: {"de" => "/german", "fr" => "/france"})]
          class CompileController < ATH::Controller
            @[ARTA::Get(path: {"fr" => ""})]
            def action : Nil
            end
          end
        CODE
      end

      it "when a controller action has a locale that is missing a prefix" do
        assert_error "Route action 'CompileController#action' is missing a corresponding route prefix for the 'de' locale.", <<-CODE
          @[ARTA::Route(path: {"fr" => "/france"})]
          class CompileController < ATH::Controller
            @[ARTA::Get(path: {"de" => "/foo", "fr" => "/bar"})]
            def action : Nil
            end
          end
        CODE
      end

      it "has an unexpected type as the #methods" do
        assert_error "Route action 'CompileController#action' expects a 'StringLiteral | ArrayLiteral | TupleLiteral' for its 'ARTA::Route#methods' field, but got a 'NumberLiteral'.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Route("/", methods: 123)]
            def action : Nil
            end
          end
        CODE
      end

      it "requires ARTA::Route to use 'methods'" do
        assert_error "Route action 'CompileController#action' cannot change the required methods when _NOT_ using the 'ARTA::Route' annotation.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get("/", methods: "SEARCH")]
            def action : Nil; end
          end
        CODE
      end

      describe "invalid field types" do
        describe "path" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'StringLiteral | HashLiteral(StringLiteral, StringLiteral)' for its 'ARTA::Route#path' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(path: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects a 'StringLiteral | HashLiteral(StringLiteral, StringLiteral)' for its 'ARTA::Get#path' field, but got a 'NumberLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(path: 10)]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "defaults" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'HashLiteral(StringLiteral, _)' for its 'ARTA::Route#defaults' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(defaults: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects a 'HashLiteral(StringLiteral, _)' for its 'ARTA::Get#defaults' field, but got a 'NumberLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(defaults: 10)]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "locale" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'StringLiteral' for its 'ARTA::Route#locale' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(locale: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects a 'StringLiteral' for its 'ARTA::Get#locale' field, but got a 'NumberLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(locale: 10)]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "format" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'StringLiteral' for its 'ARTA::Route#format' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(format: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects a 'StringLiteral' for its 'ARTA::Get#format' field, but got a 'NumberLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(format: 10)]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "stateless" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'BoolLiteral' for its 'ARTA::Route#stateless' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(stateless: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects a 'BoolLiteral' for its 'ARTA::Get#stateless' field, but got a 'NumberLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(stateless: 10)]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "name" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'StringLiteral' for its 'ARTA::Route#name' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(name: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects a 'StringLiteral' for its 'ARTA::Get#name' field, but got a 'NumberLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/", name: 10)]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "requirements" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'HashLiteral(StringLiteral, StringLiteral | RegexLiteral)' for its 'ARTA::Route#requirements' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(requirements: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects a 'HashLiteral(StringLiteral, StringLiteral | RegexLiteral)' for its 'ARTA::Get#requirements' field, but got a 'NumberLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/", requirements: 10)]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "schemes" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'StringLiteral | Enumerable(StringLiteral)' for its 'ARTA::Route#schemes' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(schemes: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "methods" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'StringLiteral | Enumerable(StringLiteral)' for its 'ARTA::Route#methods' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(methods: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "host" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'StringLiteral | RegexLiteral' for its 'ARTA::Route#host' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(host: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects a 'StringLiteral | RegexLiteral' for its 'ARTA::Get#host' field, but got a 'NumberLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/", host: 10)]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "condition" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects an 'ART::Route::Condition' for its 'ARTA::Route#condition' field, but got a 'NumberLiteral'.", <<-CODE
              @[ARTA::Route(condition: 10)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects an 'ART::Route::Condition' for its 'ARTA::Get#condition' field, but got a 'NumberLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/", condition: 10)]
                def action : Nil; end
              end
            CODE
          end
        end

        describe "priority" do
          it "controller ann" do
            assert_error "Route action 'CompileController' expects a 'NumberLiteral' for its 'ARTA::Route#priority' field, but got a 'BoolLiteral'.", <<-CODE
              @[ARTA::Route(priority: true)]
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                def action : Nil; end
              end
            CODE
          end

          it "route ann" do
            assert_error "Route action 'CompileController#action' expects a 'NumberLiteral' for its 'ARTA::Get#priority' field, but got a 'BoolLiteral'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(priority: false)]
                def action : Nil; end
              end
            CODE
          end
        end
      end
    end

    describe ATHA::ParamConverter do
      it "missing name" do
        assert_error "Route action 'CompileController#action' has an ATHA::ParamConverter annotation but is missing the argument's name. It was not provided as the first positional argument nor via the 'name' field.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::ParamConverter]
            def action(num : Int32) : Int32
              num
            end
          end
        CODE
      end

      it "missing corresponding action argument" do
        assert_error "Route action 'CompileController#action' has an ATHA::ParamConverter annotation but does not have a corresponding action argument for 'foo'.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::ParamConverter("foo")]
            def action(num : Int32) : Int32
              num
            end
          end
        CODE
      end

      it "missing converter argument" do
        assert_error "Route action 'CompileController#action' has an ATHA::ParamConverter annotation but is missing the converter class. It was not provided via the 'converter' field.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::ParamConverter("num")]
            def action(num : Int32) : Int32
              num
            end
          end
        CODE
      end

      it "missing `#apply` definition" do
        assert_error "abstract `def Athena::Framework::ParamConverter#apply(request : ATH::Request, configuration : Configuration)` must be implemented by 'CompileConverter'.", <<-CODE
          class CompileConverter < ATH::ParamConverter; end

          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::ParamConverter("num", converter: CompileConverter)]
            def action(num : Int32) : Int32
              num
            end
          end
        CODE
      end
    end

    describe ATH::RequestBodyConverter do
      it "when the action argument is not serializable" do
        assert_error "'Athena::Framework::RequestBodyConverter' cannot convert 'Foo', as it is not serializable. 'Foo' must include `JSON::Serializable` or `ASR::Serializable`.", <<-CODE
          record Foo, text : String

          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::ParamConverter("foo", converter: ATH::RequestBodyConverter)]
            def action(foo : Foo) : Foo
              foo
            end
          end
        CODE
      end
    end

    describe ATHA::QueryParam do
      it "missing name" do
        assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation but is missing the argument's name. It was not provided as the first positional argument nor via the 'name' field.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::QueryParam]
            def action(all : Bool) : Int32
              123
            end
          end
        CODE
      end

      it "missing corresponding action argument" do
        assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation but does not have a corresponding action argument for 'foo'.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::QueryParam("foo")]
            def action(active : Bool) : Bool
              active
            end
          end
        CODE
      end

      it "disallows non nilable non strict and no default params" do
        assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation with `strict: false` but the related action argument is not nilable nor has a default value.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get("/")]
            @[ATHA::QueryParam("page", strict: false)]
            def action(page : Int32) : Int32
              page
            end
          end
        CODE
      end

      describe "requirements" do
        describe "only allows `Assert` annotations as requirements (other than regex)" do
          it "with a single annotation" do
            assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation whose 'requirements' value is invalid. Expected `Assert` annotation, got '@[ARTA::Get]'.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                @[ATHA::QueryParam("all", requirements: @[ARTA::Get])]
                def action(all : Bool) : Int32
                  123
                end
              end
            CODE
          end

          describe "in an array" do
            it "with a scalar value" do
              assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation whose 'requirements' array contains an invalid value. Expected `Assert` annotation, got '1' at index 1.", <<-CODE
                class CompileController < ATH::Controller
                  @[ARTA::Get(path: "/")]
                  @[ATHA::QueryParam("all", requirements: [@[Assert::NotBlank], 1])]
                  def action(all : Bool) : Int32
                    123
                  end
                end
              CODE
            end

            it "with an annotation value" do
              assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation whose 'requirements' array contains an invalid value. Expected `Assert` annotation, got '@[ARTA::Get]' at index 1.", <<-CODE
                class CompileController < ATH::Controller
                  @[ARTA::Get(path: "/")]
                  @[ATHA::QueryParam("all", requirements: [@[Assert::NotBlank], @[ARTA::Get]])]
                  def action(all : Bool) : Int32
                    123
                  end
                end
              CODE
            end
          end

          it "with a scalar requirements value" do
            assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation with an invalid 'requirements' type: 'StringLiteral'. Only Regex, NamedTuple, or Array values are supported.", <<-CODE
              class CompileController < ATH::Controller
                @[ARTA::Get(path: "/")]
                @[ATHA::QueryParam("all", requirements: "foo")]
                def action(all : Bool) : Int32
                  123
                end
              end
            CODE
          end
        end
      end

      describe "converter" do
        it "disallows non NamedTuple and Paths" do
          assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation with an invalid 'converter' type: 'StringLiteral'. Only NamedTuples, or the converter class are supported.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::QueryParam("all", converter: "foo")]
            def action(all : Bool) : Int32
              123
            end
          end
        CODE
        end

        it "disallows non ATH::ParamConverter types" do
          assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation with an invalid 'converter' value. Expected 'ATH::ParamConverter.class' got 'Athena::Framework::Controller'.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::QueryParam("all", converter: ATH::Controller)]
            def action(all : Bool) : Int32
              123
            end
          end
        CODE
        end

        it "requires the name to be provided when using a NamedTuple" do
          assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::QueryParam annotation with an invalid 'converter'. The converter's name was not provided via the 'name' field.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::QueryParam("all", converter: {format: "%Y--%m//%d %T"})]
            def action(all : Bool) : Int32
              123
            end
          end
        CODE
        end
      end
    end

    # This is essentially the same as `ATHA::QueryParam`.
    # Just do a simple check to ensure its working as expected while doing most other assertions with `ATHA::QueryParam`.
    describe ATHA::RequestParam do
      it "missing name" do
        assert_error "Route action 'CompileController#action' has an Athena::Framework::Annotations::RequestParam annotation but is missing the argument's name. It was not provided as the first positional argument nor via the 'name' field.", <<-CODE
          class CompileController < ATH::Controller
            @[ARTA::Get(path: "/")]
            @[ATHA::RequestParam]
            def action(all : Bool) : Int32
              123
            end
          end
        CODE
      end
    end
  end
end
