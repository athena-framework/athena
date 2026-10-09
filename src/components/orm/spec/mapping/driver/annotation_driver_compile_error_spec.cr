require "../../spec_helper"

private def assert_mapping_compile_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, code, preamble: %(require "../../../src/athena-orm"), postamble: %(AORM::EntityManager.new DB.connect("sqlite3::memory:")), line: line
end

# Mapping errors the annotation driver reports at compile time.
# Options that aren't supported yet are rejected here rather than silently ignored.
struct AnnotationDriverCompileErrorTest < ASPEC::TestCase
  @[Tags("compiled")]
  def test_lifecycle_callback_with_too_many_parameters : Nil
    assert_mapping_compile_error "Expected 'Widget#on_persist' to have 0..1 parameters, got '2'.", <<-CR
      @[AORMA::Entity]
      class Widget < AORM::Entity
        @[AORMA::Column]
        @[AORMA::ID]
        property id : Int64? = nil

        @[AORMA::PrePersist]
        def on_persist(a, b) : Nil
        end
      end
      CR
  end

  @[Tags("compiled")]
  def test_post_load_callback : Nil
    assert_mapping_compile_error "'Widget#on_load': PostLoad lifecycle callbacks are not supported yet.", <<-CR
      @[AORMA::Entity]
      class Widget < AORM::Entity
        @[AORMA::Column]
        @[AORMA::ID]
        property id : Int64? = nil

        @[AORMA::PostLoad]
        def on_load : Nil
        end
      end
      CR
  end

  @[Tags("compiled")]
  def test_generated_column : Nil
    assert_mapping_compile_error "'Widget#total': the 'generated' column option is not supported yet.", <<-CR
      @[AORMA::Entity]
      class Widget < AORM::Entity
        @[AORMA::Column]
        @[AORMA::ID]
        property id : Int64? = nil

        @[AORMA::Column(generated: "ALWAYS")]
        property total : Int32? = nil
      end
      CR
  end

  # Only abstract classes may inherit from `AORM::Entity` without being entities, to share mapped properties.
  @[Tags("compiled")]
  def test_concrete_class_without_entity_annotation : Nil
    assert_mapping_compile_error "'Widget' is not a valid entity or superclass", <<-CR
      class Widget < AORM::Entity
        @[AORMA::Column]
        @[AORMA::ID]
        property id : Int64? = nil
      end

      AORM::EntityManager.new(DB.connect("sqlite3::memory:")).class_metadata Widget
      CR
  end

  @[Tags("compiled")]
  def test_embeddable : Nil
    assert_mapping_compile_error "'Address': embeddables are not supported yet.", <<-CR
      @[AORMA::Embeddable]
      class Address < AORM::Entity
        @[AORMA::Column]
        property street : String? = nil
      end
      CR
  end
end
