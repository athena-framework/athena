require "./spec_helper"

struct CharsetNegotiatorTest < NegotiatorTestCase
  @negotiator : ANG::CharsetNegotiator

  def initialize
    @negotiator = ANG::CharsetNegotiator.new
  end

  def test_best_unmatched_header : Nil
    @negotiator.best("foo, bar, yo", {"baz"}).should be_nil
  end

  def test_best_ignores_missing_content : Nil
    accept = @negotiator.best "en; q=0.1, fr; q=0.4, bu; q=1.0", {"en", "fr"}

    accept = accept.should_not be_nil
    accept.should be_a ANG::AcceptCharset
    accept.charset.should eq "fr"
  end

  def test_best_respects_priorities : Nil
    accept = @negotiator.best "foo, bar, yo", {"yo"}
    accept = accept.should_not be_nil
    accept.should be_a ANG::AcceptCharset
    accept.charset.should eq "yo"
  end

  def test_best_respects_quality : Nil
    accept = @negotiator.best "utf-8;q=0.5,iso-8859-1", {"iso-8859-1;q=0.3", "utf-8;q=0.9", "utf-16;q=1.0"}
    accept = accept.should_not be_nil
    accept.should be_a ANG::AcceptCharset
    accept.charset.should eq "utf-8"
  end

  @[DataProvider("best_data_provider")]
  def test_best(header : String, priorities : Indexable(String), expected : String?) : Nil
    accept = @negotiator.best header, priorities

    if accept.nil?
      expected.should be_nil
    else
      accept.should be_a ANG::AcceptCharset
      accept.header.should eq expected
    end
  end

  def best_data_provider : Tuple
    php_pear_charset = "ISO-8859-1, Big5;q=0.6,utf-8;q=0.7, *;q=0.5"
    php_pear_charset2 = "ISO-8859-1, Big5;q=0.6,utf-8;q=0.7"

    {
      {php_pear_charset, {"utf-8", "big5", "iso-8859-1", "shift-jis"}, "iso-8859-1"},
      {php_pear_charset, {"utf-8", "big5", "shift-jis"}, "utf-8"},
      {php_pear_charset, {"Big5", "shift-jis"}, "Big5"},
      {php_pear_charset, {"shift-jis"}, "shift-jis"},
      {php_pear_charset2, {"utf-8", "big5", "iso-8859-1", "shift-jis"}, "iso-8859-1"},
      {php_pear_charset2, {"utf-8", "big5", "shift-jis"}, "utf-8"},
      {php_pear_charset2, {"Big5", "shift-jis"}, "Big5"},
      {"utf-8;q=0.6,iso-8859-5;q=0.9", {"iso-8859-5", "utf-8"}, "iso-8859-5"},
      {"en, *;q=0.9", {"fr"}, "fr"},
      # Quality of source factors
      {php_pear_charset, {"iso-8859-1;q=0.5", "utf-8", "utf-16;q=1.0"}, "utf-8"},
      {php_pear_charset, {"iso-8859-1;q=0.8", "utf-8", "utf-16;q=1.0"}, "iso-8859-1;q=0.8"},
    }
  end
end
