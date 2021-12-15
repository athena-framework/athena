require "./spec_helper"

struct EncodingNegotiatorTest < NegotiatorTestCase
  @negotiator : ANG::EncodingNegotiator

  def initialize
    @negotiator = ANG::EncodingNegotiator.new
  end

  def test_best_unmatched_header : Nil
    @negotiator.best("foo, bar, yo", {"baz"}).should be_nil
  end

  def test_best_respects_quality : Nil
    accept = @negotiator.best "gzip;q=0.7,identity", {"identity;q=0.5", "gzip;q=0.9"}
    accept = accept.should_not be_nil
    accept.should be_a ANG::AcceptEncoding
    accept.coding.should eq "gzip"
  end

  @[DataProvider("best_data_provider")]
  def test_best(header : String, priorities : Indexable(String), expected : String?) : Nil
    accept = @negotiator.best header, priorities

    if accept.nil?
      expected.should be_nil
    else
      accept.should be_a ANG::AcceptEncoding
      accept.header.should eq expected
    end
  end

  def best_data_provider : Tuple
    {
      {"gzip;q=1.0, identity; q=0.5, *;q=0", {"identity"}, "identity"},
      {"gzip;q=0.5, identity; q=0.5, *;q=0.7", {"bzip", "foo"}, "bzip"},
      {"gzip;q=0.7, identity; q=0.5, *;q=0.7", {"gzip", "foo"}, "gzip"},
      # Quality of source factors
      {"gzip;q=0.7,identity", {"identity;q=0.5", "gzip;q=0.9"}, "gzip;q=0.9"},
    }
  end
end
