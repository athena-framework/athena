require "./spec_helper"

struct AHTTP::HeaderUtilsTest < ASPEC::TestCase
  @[TestWith(
    {"foo", "foo"},
    {"az09!#$%&'*.^_`|~-", "az09!#$%&'*.^_`|~-"},
    {"\"foo bar\"", "foo bar"},
    {"\"foo [bar]\"", "foo [bar]"},
    {"\"foo \\\"bar\\\"\"", "foo \"bar\""},
    {"\"foo \\\"\\b\\a\\r\\\"\"", "foo \"bar\""},
    {"\"foo \\\\ bar\"", "foo \\ bar"},
  )]
  def test_unquote(input : String, expected : String) : Nil
    AHTTP::HeaderUtils.unquote(input).should eq expected
  end

  @[TestWith(
    {[["foo", "123"]], {"foo" => "123"}},
    {[["foo"]], {"foo" => true}},
    {[["Foo"]], {"foo" => true}},
    {[["foo", "123"], ["bar"]], {"foo" => "123", "bar" => true}}
  )]
  def test_combine(input : Array, expected : Hash) : Nil
    AHTTP::HeaderUtils.combine(input).should eq expected
  end

  def test_to_string : Nil
    AHTTP::HeaderUtils.to_string({"foo" => true}, ',').should eq "foo"
    AHTTP::HeaderUtils.to_string({"foo" => true, "bar" => true}, ';').should eq "foo;bar"
    AHTTP::HeaderUtils.to_string({"foo" => 123}, ',').should eq "foo=123"
    AHTTP::HeaderUtils.to_string({"foo" => "1 2 3"}, ',').should eq "foo=1\\ 2\\ 3"
    AHTTP::HeaderUtils.to_string({"foo" => "1 2 3", "bar" => true}, ',').should eq "foo=1\\ 2\\ 3,bar"

    # Named arg overload
    AHTTP::HeaderUtils.to_string("-", foo: true, bar: 2.0).should eq "foo-bar=2.0"

    # IO overload
    String.build do |io|
      io << '~'
      AHTTP::HeaderUtils.to_string io, {"foo" => true, "bar" => 100, "baz" => false}, "|"
      io << '~'
    end.should eq "~foo|bar=100|baz=false~"
  end

  @[DataProvider("headers_to_split")]
  def test_split(expected : Array, header : String, separator : String) : Nil
    AHTTP::HeaderUtils.split(header, separator).should eq expected
  end

  def headers_to_split : Tuple
    {
      {["foo=123", "bar"], "foo=123,bar", ","},
      {["foo=123", "bar"], "foo=123, bar", ","},
      {[["foo=123", "bar"]], "foo=123; bar", ",;"},
      {[["foo=123"], ["bar"]], "foo=123, bar", ",;"},
      {["foo", "123, bar"], "foo=123, bar", "="},
      {["foo", "123, bar"], " foo = 123, bar ", "="},
      {[["foo", "123"], ["bar"]], "foo=123, bar", ",="},
      {[[["foo", "123"]], [["bar"], ["foo", "456"]]], "foo=123, bar;; foo=456", ",;="},
      {[[["foo", "a,b;c=d"]]], "foo=\"a,b;c=d\"", ",;="},

      {["foo", "bar"], "foo,,,, bar", ","},
      {["foo", "bar"], ",foo, bar,", ","},
      {["foo", "bar"], " , foo, bar, ", ","},
      {["foo bar"], "foo \"bar\"", ","},
      {["foo bar"], "\"foo\" bar", ","},
      {["foo bar"], "\"foo\" \"bar\"", ","},

      {[["foo_cookie", "foo=1&bar=2&baz=3"], ["expires", "Tue, 22-Sep-2020 06:27:09 GMT"], ["path", "/"]], "foo_cookie=foo=1&bar=2&baz=3; expires=Tue, 22-Sep-2020 06:27:09 GMT; path=/", ";="},
      {[["foo_cookie", "foo=="], ["expires", "Tue, 22-Sep-2020 06:27:09 GMT"], ["path", "/"]], "foo_cookie=foo==; expires=Tue, 22-Sep-2020 06:27:09 GMT; path=/", ";="},
      {[["foo_cookie", "foo="], ["expires", "Tue, 22-Sep-2020 06:27:09 GMT"], ["path", "/"]], "foo_cookie=foo=; expires=Tue, 22-Sep-2020 06:27:09 GMT; path=/", ";="},
      {[["foo_cookie", "foo=a=b"], ["expires", "Tue, 22-Sep-2020 06:27:09 GMT"], ["path", "/"]], "foo_cookie=foo=\"a=b\"; expires=Tue, 22-Sep-2020 06:27:09 GMT; path=/", ";="},

      # These are not a valid header values. We test that they parse anyway, and that both the valid and invalid parts are returned.
      {[] of String, "", ","},
      {[] of String, ",,,", ","},
      {[["", "foo"], ["bar", ""]], "=foo,bar=", ",="},
      {["foo", "foobar", "baz"], "foo, foo\"bar\", \"baz", ","},
      {["foo", "bar, baz"], "foo, \"bar, baz", ","},
      {["foo", "bar, baz\\"], "foo, \"bar, baz\\", ","},
      {["foo", "bar, baz\\"], "foo, \"bar, baz\\", ","},
    }
  end

  @[DataProvider("dispositions")]
  def test_make_disposition(disposition : AHTTP::BinaryFileResponse::ContentDisposition, filename : String, fallback_filename : String?, expected : String) : Nil
    AHTTP::HeaderUtils.make_disposition(disposition, filename, fallback_filename).should eq expected
  end

  def dispositions : Tuple
    {
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "foo.html", "foo.html", "attachment; filename=foo.html"},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "foo.html", nil, "attachment; filename=foo.html"},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "foo bar.html", nil, "attachment; filename=foo\\ bar.html"},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, %(foo "bar".html), nil, %(attachment; filename=foo\\ \\"bar\\".html)},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "foo%20bar.html", "foo bar.html", "attachment; filename=foo\\ bar.html; filename*=utf-8''foo%2520bar.html"},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "föö.html", "foo.html", "attachment; filename=foo.html; filename*=utf-8''f%C3%B6%C3%B6.html"},
    }
  end

  @[DataProvider("invalid_dispositions")]
  def test_invalid_dispositions(disposition : AHTTP::BinaryFileResponse::ContentDisposition, filename : String, expected : String, fallback_filename : String? = nil) : Nil
    expect_raises ArgumentError, expected do
      AHTTP::HeaderUtils.make_disposition disposition, filename, fallback_filename
    end
  end

  def invalid_dispositions : Tuple
    {
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "foo%20bar.html", "The fallback filename cannot contain the '%' character.", nil},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "foo/bar.html", "The filename cannot include path separators.", nil},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "/foo.html", "The filename cannot include path separators.", nil},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "foo\\bar.html", "The filename cannot include path separators.", nil},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "\\foo.html", "The filename cannot include path separators.", nil},
      {AHTTP::BinaryFileResponse::ContentDisposition::Attachment, "foo.html", "The fallback filename cannot include path separators.", "f/oo.html"},
    }
  end
end
