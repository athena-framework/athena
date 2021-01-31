require "./spec_helper"

struct ART::HeaderUtilsTest < ASPEC::TestCase
  def test_to_string : Nil
    ART::HeaderUtils.to_string({"foo" => true}, ',').should eq "foo"
    ART::HeaderUtils.to_string({"foo" => true, "bar" => true}, ';').should eq "foo;bar"
    ART::HeaderUtils.to_string({"foo" => 123}, ',').should eq "foo=123"
    ART::HeaderUtils.to_string({"foo" => "1 2 3"}, ',').should eq "foo=1\\ 2\\ 3"
    ART::HeaderUtils.to_string({"foo" => "1 2 3", "bar" => true}, ',').should eq "foo=1\\ 2\\ 3,bar"

    # Named arg overload
    ART::HeaderUtils.to_string("-", foo: true, bar: 2.0).should eq "foo-bar=2.0"

    # IO overload
    String.build do |io|
      io << '~'
      ART::HeaderUtils.to_string io, {"foo" => true, "bar" => 100, "baz" => false}, "|"
      io << '~'
    end.should eq "~foo|bar=100|baz=false~"
  end

  @[DataProvider("dispositions")]
  def test_make_disposition(disposition : ART::BinaryFileResponse::ContentDisposition, filename : String, fallback_filename : String?, expected : String) : Nil
    ART::HeaderUtils.make_disposition(disposition, filename, fallback_filename).should eq expected
  end

  def dispositions : Tuple
    {
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "foo.html", "foo.html", "attachment; filename=foo.html"},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "foo.html", nil, "attachment; filename=foo.html"},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "foo bar.html", nil, "attachment; filename=foo\\ bar.html"},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, %(foo "bar".html), nil, %(attachment; filename=foo\\ \\"bar\\".html)},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "foo%20bar.html", "foo bar.html", "attachment; filename=foo\\ bar.html; filename*=UTF-8''foo%2520bar.html"},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "föö.html", "foo.html", "attachment; filename=foo.html; filename*=UTF-8''f%C3%B6%C3%B6.html"},
    }
  end

  @[DataProvider("invalid_dispositions")]
  def test_invalid_dispositions(disposition : ART::BinaryFileResponse::ContentDisposition, filename : String, expected : String, fallback_filename : String? = nil) : Nil
    expect_raises ArgumentError, expected do
      ART::HeaderUtils.make_disposition disposition, filename, fallback_filename
    end
  end

  def invalid_dispositions : Tuple
    {
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "foo%20bar.html", "The fallback filename cannot contain the '%' character.", nil},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "foo/bar.html", "The filename cannot include path separators.", nil},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "/foo.html", "The filename cannot include path separators.", nil},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "foo\\bar.html", "The filename cannot include path separators.", nil},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "\\foo.html", "The filename cannot include path separators.", nil},
      {ART::BinaryFileResponse::ContentDisposition::Attachment, "foo.html", "The fallback filename cannot include path separators.", "f/oo.html"},
    }
  end
end
