require "./spec_helper"

struct AcceptTest < ASPEC::TestCase
  def test_parameters : Nil
    ANG::Accept.new("foo/bar; q=1; hello=world").parameters["hello"]?.should eq "world"
  end

  @[DataProvider("normalized_header_data_provider")]
  def test_normalized_header(header : String, expected : String) : Nil
    ANG::Accept.new(header).normalized_header.should eq expected
  end

  def normalized_header_data_provider : Tuple
    {
      {"text/html  ; z=y; a  = b; c=d", "text/html; a=b; c=d; z=y"},
      {"application/pdf; q=1; param=p", "application/pdf; param=p"},
    }
  end

  @[DataProvider("media_range_data_provider")]
  def test_media_range(header : String, expected : String) : Nil
    ANG::Accept.new(header).media_range.should eq expected
  end

  def media_range_data_provider : Tuple
    {
      {"text/html;hello=world", "text/html"},
      {"application/pdf", "application/pdf"},
      {"application/xhtml+xml;q=0.9", "application/xhtml+xml"},
      {"text/plain; q=0.5", "text/plain"},
      {"text/html;level=2;q=0.4", "text/html"},
      {"text/html ; level = 2   ; q = 0.4", "text/html"},
      {"text/*", "text/*"},
      {"text/* ;q=1 ;level=2", "text/*"},
      {"*/*", "*/*"},
      {"*", "*/*"},
      {"*/* ; param=555", "*/*"},
      {"* ; param=555", "*/*"},
      {"TEXT/hTmL;leVel=2; Q=0.4", "text/html"},
    }
  end

  @[DataProvider("header_data_provider")]
  def test_accept_value(header : String, expected : String) : Nil
    ANG::Accept.new(header).header.should eq expected
  end

  def header_data_provider : Tuple
    {
      {"text/html;hello=world  ;q=0.5", "text/html;hello=world  ;q=0.5"},
      {"application/pdf", "application/pdf"},
    }
  end
end
