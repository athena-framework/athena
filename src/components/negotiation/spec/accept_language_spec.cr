require "./spec_helper"

struct AcceptLanguageTest < ASPEC::TestCase
  @[DataProvider("accept_value_data_provider")]
  def test_accept_value(header : String?, expected : String?) : Nil
    ANG::AcceptLanguage.new(header).accept_value.should eq expected
  end

  def accept_value_data_provider : Tuple
    {
      {"en;q=0.7", "en"},
      {"en-GB;q=0.8", "en-gb"},
      {"da", "da"},
      {"en-gb;q=0.8", "en-gb"},
      {"es;q=0.7", "es"},
      {"fr ; q= 0.1", "fr"},
    }
  end

  @[DataProvider("header_data_provider")]
  def test_get_value(header : String?, expected : String?) : Nil
    ANG::AcceptLanguage.new(header).header.should eq expected
  end

  def header_data_provider : Tuple
    {
      {"en;q=0.7", "en;q=0.7"},
      {"en-GB;q=0.8", "en-GB;q=0.8"},
    }
  end

  @[TestWith(
    {"en;q=0.7", "en"},
    {"en-GB;q=0.8", "en-gb"},
    {"zh-Hans-CN;q=0.8", "zh-hans-cn"},
  )]
  def test_language_range(header : String, expected : String) : Nil
    ANG::AcceptLanguage.new(header).language_range.should eq expected
  end
end
