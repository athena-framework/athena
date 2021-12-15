require "./spec_helper"

struct AcceptMatchTest < ASPEC::TestCase
  @[DataProvider("compare_data_provider")]
  def test_compare(match1 : ANG::AcceptMatch, match2 : ANG::AcceptMatch, expected : Int32) : Nil
    (match1 <=> match2).should eq expected
  end

  def compare_data_provider : Tuple
    {
      {ANG::AcceptMatch.new(1.0, 110, 1), ANG::AcceptMatch.new(1.0, 111, 1), 0},
      {ANG::AcceptMatch.new(0.1, 10, 1), ANG::AcceptMatch.new(0.1, 10, 2), -1},
      {ANG::AcceptMatch.new(0.5, 110, 5), ANG::AcceptMatch.new(0.5, 11, 4), 1},
      {ANG::AcceptMatch.new(0.4, 110, 1), ANG::AcceptMatch.new(0.6, 111, 3), 1},
      {ANG::AcceptMatch.new(0.6, 110, 1), ANG::AcceptMatch.new(0.4, 111, 3), -1},
    }
  end

  @[DataProvider("reduce_data_provider")]
  def test_reduce(matches : Hash(Int32, ANG::AcceptMatch), match : ANG::AcceptMatch, expected : Hash(Int32, ANG::AcceptMatch)) : Nil
    ANG::AcceptMatch.reduce(matches, match).should eq expected
  end

  def reduce_data_provider : Tuple
    {
      {
        {1 => ANG::AcceptMatch.new(1.0, 10, 1)},
        ANG::AcceptMatch.new(0.5, 111, 1),
        {1 => ANG::AcceptMatch.new(0.5, 111, 1)},
      },
      {
        {1 => ANG::AcceptMatch.new(1.0, 110, 1)},
        ANG::AcceptMatch.new(0.5, 11, 1),
        {1 => ANG::AcceptMatch.new(1.0, 110, 1)},
      },
      {
        {0 => ANG::AcceptMatch.new(1.0, 10, 1)},
        ANG::AcceptMatch.new(0.5, 111, 1),
        {0 => ANG::AcceptMatch.new(1.0, 10, 1), 1 => ANG::AcceptMatch.new(0.5, 111, 1)},
      },
    }
  end
end
