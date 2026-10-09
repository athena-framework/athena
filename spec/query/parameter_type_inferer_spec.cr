require "../spec_helper"

struct ParameterTypeInfererTest < ASPEC::TestCase
  @[DataProvider("parameter_types")]
  def test_infer_type(value : DB::Any, expected : String?) : Nil
    AORM::Query::ParameterTypeInferer.infer_type(value).should eq expected
  end

  def parameter_types : Hash
    {
      "integer"        => {1, AORM::Types::INTEGER},
      "bigint"         => {1_i64, AORM::Types::BIGINT},
      "boolean"        => {true, AORM::Types::BOOLEAN},
      "datetime"       => {Time.utc, AORM::Types::DATETIME},
      "string"         => {"bar", nil},
      "numeric string" => {"1", nil},
      "nil"            => {nil, nil},
    }
  end
end
