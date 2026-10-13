require "../../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, line: line, preamble: <<-'CR', postamble: "ATH.run"
    require "../../../src/athena"
    require "athena-validator"
  CR
end

private def assert_compiles(code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compiles code, line: line, preamble: <<-'CR', postamble: "ATH.run"
    require "../../../src/athena"
    require "athena-validator"
  CR
end

describe "Validator bundle not registered", tags: "compiled" do
  it "resolves request bodies without the Validator component" do
    ASPEC::Methods.assert_executes <<-'CR'
      require "../../../src/athena"
      require "../../../src/spec"

      record JSONEntity, id : Int32 do
        include JSON::Serializable
      end

      record FormEntity, id : Int32 do
        include URI::Params::Serializable
      end

      class NativeController < ATH::Controller
        @[ARTA::Post("/json")]
        def json(@[ATHA::MapRequestBody] entity : JSONEntity) : JSONEntity
          entity
        end

        @[ARTA::Get("/query")]
        def query(@[ATHA::MapQueryString] entity : FormEntity) : Int32
          entity.id
        end
      end

      struct WithoutValidatorTest < ATH::Spec::APITestCase
        def test_json_request_body : Nil
          self.post("/json", %({"id":10}), headers: HTTP::Headers{"content-type" => "application/json"}).body.should eq %({"id":10})
        end

        def test_query_string : Nil
          self.get("/query?id=10").body.should eq "10"
        end
      end

      ASPEC.run_all

      raise "Expected the Validator component to not be required" if {{ @top_level.has_constant? "AVD" }}
    CR
  end

  describe "with the Validator component" do
    it "resolves request bodies that are not validatable" do
      assert_compiles <<-'CR'
        record JSONEntity, id : Int32 do
          include JSON::Serializable
        end

        class CompileController < ATH::Controller
          @[ARTA::Post("/")]
          def action(@[ATHA::MapRequestBody] entity : JSONEntity, @[ATHA::MapUploadedFile] file : AHTTP::UploadedFile?) : JSONEntity
            entity
          end
        end
      CR
    end

    it "errors if a request body is AVD::Validatable" do
      assert_compile_time_error "The type of route action parameter 'CompileController#action:entity' is 'ValidatableEntity', which includes 'AVD::Validatable', but the Validator bundle is not registered. Add `require \"athena-validator/bundle\"` to validate it.", <<-'CR'
        record ValidatableEntity, id : Int32 do
          include AVD::Validatable
          include JSON::Serializable
        end

        class CompileController < ATH::Controller
          @[ARTA::Post("/")]
          def action(@[ATHA::MapRequestBody] entity : ValidatableEntity) : Nil
          end
        end
      CR
    end

    it "errors if a nilable query string is AVD::Validatable" do
      assert_compile_time_error "The type of route action parameter 'CompileController#action:entity' is '(ValidatableEntity | Nil)', which includes 'AVD::Validatable', but the Validator bundle is not registered. Add `require \"athena-validator/bundle\"` to validate it.", <<-'CR'
        record ValidatableEntity, id : Int32 do
          include AVD::Validatable
          include URI::Params::Serializable
        end

        class CompileController < ATH::Controller
          @[ARTA::Get("/")]
          def action(@[ATHA::MapQueryString] entity : ValidatableEntity?) : Nil
          end
        end
      CR
    end

    it "errors if validation groups are set" do
      assert_compile_time_error "Route action parameter 'CompileController#action:entity' sets 'validation_groups' on '@[ATHA::MapRequestBody]', but the Validator bundle is not registered. Add `require \"athena-validator/bundle\"` to validate it.", <<-'CR'
        record JSONEntity, id : Int32 do
          include JSON::Serializable
        end

        class CompileController < ATH::Controller
          @[ARTA::Post("/")]
          def action(@[ATHA::MapRequestBody(validation_groups: ["strict"])] entity : JSONEntity) : Nil
          end
        end
      CR
    end

    it "errors if uploaded file constraints are set" do
      assert_compile_time_error "Route action parameter 'CompileController#action:file' sets 'constraints' on '@[ATHA::MapUploadedFile]', but the Validator bundle is not registered. Add `require \"athena-validator/bundle\"` to validate it.", <<-'CR'
        class CompileController < ATH::Controller
          @[ARTA::Post("/")]
          def action(@[ATHA::MapUploadedFile(constraints: AVD::Constraints::File.new)] file : AHTTP::UploadedFile) : Nil
          end
        end
      CR
    end
  end
end
