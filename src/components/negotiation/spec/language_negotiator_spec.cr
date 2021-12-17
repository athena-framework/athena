require "./spec_helper"

struct LanguageNegotiatorTest < NegotiatorTestCase
  @negotiator : ANG::LanguageNegotiator

  def initialize
    @negotiator = ANG::LanguageNegotiator.new
  end

  def test_best_respects_quality : Nil
    accept = @negotiator.best "en;q=0.5,de", {"de;q=0.3", "en;q=0.9"}
    accept = accept.should_not be_nil
    accept.should be_a ANG::AcceptLanguage
    accept.language.should eq "en"
  end

  @[DataProvider("best_data_provider")]
  def test_best(header : String, priorities : Indexable(String), expected : String?) : Nil
    accept = @negotiator.best header, priorities

    if accept.nil?
      expected.should be_nil
    else
      accept.should be_a ANG::AcceptLanguage
      accept.header.should eq expected
    end
  end

  def best_data_provider : Tuple
    {
      {"en, de", {"fr"}, nil},
      {"foo, bar, yo", {"baz", "biz"}, nil},
      {"fr-FR, en;q=0.8", {"en-US", "de-DE"}, "en-US"},
      {"en, *;q=0.9", {"fr"}, "fr"},
      {"foo, bar, yo", {"yo"}, "yo"},
      {"en; q=0.1, fr; q=0.4, bu; q=1.0", {"en", "fr"}, "fr"},
      {"en; q=0.1, fr; q=0.4, fu; q=0.9, de; q=0.2", {"en", "fu"}, "fu"},
      {"fr, zh-Hans-CN;q=0.3", {"fr"}, "fr"},
      # Quality of source factors
      {"en;q=0.5,de", {"de;q=0.3", "en;q=0.9"}, "en;q=0.9"},
    }
  end
end
