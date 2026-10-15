require "./spec_helper"

struct QueryTest < ASPEC::TestCase
  def test_to_s_is_the_statement : Nil
    AORM::Migrations::Query.new("SELECT 1").to_s.should eq "SELECT 1"
  end

  def test_more_types_than_parameters_raises : Nil
    expect_raises AORM::Migrations::Exception::InvalidArguments, %(The number of types (2) is higher than the number of passed parameters (1) for the query "SELECT ?".) do
      AORM::Migrations::Query.new "SELECT ?", [1] of DB::Any, [AORM::Types::INTEGER, AORM::Types::INTEGER] of String?
    end
  end
end
