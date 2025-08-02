require "./spec_helper"

struct ATH::BinaryFileResponseTest < ASPEC::TestCase
  def test_new_without_disposition : Nil
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/foo.txt", 418, HTTP::Headers{"FOO" => "BAR"}, true, nil, true, true
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.headers["FOO"]?.should eq "BAR"
    response.headers.has_key?("etag").should be_true
    response.headers.has_key?("last-modified").should be_true
    response.headers.has_key?("content-disposition").should be_false
  end

  def test_new_with_disposition : Nil
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/foo.txt", 418, public: true, content_disposition: :inline
    response.status.should eq HTTP::Status::IM_A_TEAPOT
    response.headers.has_key?("etag").should be_false
    response.headers.has_key?("content-disposition").should be_true
    response.headers["content-disposition"]?.should eq %(inline; filename=foo.txt)
  end

  def test_new_with_non_ascii_filename : Nil
    ATH::BinaryFileResponse.new("#{__DIR__}/assets/fööö.html").file.basename.should eq "fööö.html"
  end

  def test_set_file_unreadable : Nil
    pending! "Windows does not have unreadable files" if {{ flag? :windows }}

    path = Path[Dir.tempdir, "unreadable"].to_s

    begin
      ::File.write path, "", 0

      ex = expect_raises ATH::Exception::File, "The file must be readable." do
        ATH::BinaryFileResponse.new path
      end

      ex.file.should eq path
    ensure
      ::File.delete? path
    end
  end

  def test_set_content : Nil
    expect_raises(::Exception, "The content cannot be set on a BinaryFileResponse instance.") do
      ATH::BinaryFileResponse.new(__FILE__).content = "FOO"
    end
  end

  def test_content : Nil
    ATH::BinaryFileResponse.new(__FILE__).content.should be_empty
  end

  def test_set_content_disposition_custom_fallback_filename : Nil
    response = ATH::BinaryFileResponse.new __FILE__
    response.set_content_disposition :attachment, "föö.html", "FILE"

    response.headers["content-disposition"]?.should eq %(attachment; filename=FILE; filename*=utf-8''f%C3%B6%C3%B6.html)
  end

  def test_set_content_disposition_custom_filename : Nil
    response = ATH::BinaryFileResponse.new __FILE__
    response.set_content_disposition :attachment, "foo.html"

    response.headers["content-disposition"]?.should eq %(attachment; filename=foo.html)
  end

  def test_range_requests_without_last_modified_header : Nil
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif", content_disposition: nil, auto_last_modified: false

    # Request to get ETag
    request = ATH::Request.new "GET", "/", HTTP::Headers{
      "if-range" => Time::Format::HTTP_DATE.format(Time.utc),
      "range"    => "bytes=1-4",
    }

    response.prepare request
    output = String.build do |io|
      response.write io
    end

    ::File.read("#{__DIR__}/assets/test.gif").should eq output
    response.headers.has_key?("content-range").should be_false
  end

  def test_range_on_post_method : Nil
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif"

    request = ATH::Request.new "POST", "/", HTTP::Headers{"range" => "bytes=10-20"}

    expected_output = ::File.open "#{__DIR__}/assets/test.gif", &.read_string(35)

    response.prepare request

    output = String.build do |io|
      response.write io
    end

    output.should eq expected_output
    response.status.should eq HTTP::Status::OK
    response.headers["content-length"].should eq "35"
    response.headers.has_key?("content-range").should be_false
  end

  def test_unprepared_response_sends_full_file : Nil
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif"

    expected_output = ::File.read "#{__DIR__}/assets/test.gif"

    output = String.build do |io|
      response.write io
    end

    output.should eq expected_output
    response.status.should eq HTTP::Status::OK
  end

  def test_delete_file_after_send : Nil
    path = Path[Dir.tempdir, "unreadable"]

    begin
      ::File.touch path

      ::File.file?(path).should be_true

      request = ATH::Request.new "GET", "/"

      response = ATH::BinaryFileResponse.new path
      response.delete_file_after_send = true

      response.prepare request
      response.write IO::Memory.new

      ::File.file?(path).should be_false
    ensure
      ::File.delete? path
    end
  end

  def test_accept_range_unsafe_methods : Nil
    request = ATH::Request.new "POST", "/"
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif"

    response.prepare request

    response.headers["accept-ranges"]?.should eq "none"
  end

  def test_accept_range_not_overridden : Nil
    request = ATH::Request.new "POST", "/"
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif", headers: HTTP::Headers{"accept-ranges" => "foo"}

    response.prepare request

    response.headers["accept-ranges"]?.should eq "foo"
  end

  def test_prepare_cache_request_etag : Nil
    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"if-none-match" => "\"ETAG\""}
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif", headers: HTTP::Headers{"accept-ranges" => "foo", "etag" => "\"ETAG\""}

    response.prepare request

    response.status.should eq HTTP::Status::NOT_MODIFIED
    response.headers.has_key?("date").should be_true
    response.headers.has_key?("content-length").should be_false
    response.headers.has_key?("content-type").should be_false
  end

  def test_prepare_cache_request_etag_star : Nil
    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"if-none-match" => "*"}
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif", headers: HTTP::Headers{"accept-ranges" => "foo", "etag" => "\"ETAG\""}

    response.prepare request

    response.status.should eq HTTP::Status::NOT_MODIFIED
    response.headers.has_key?("date").should be_true
    response.headers.has_key?("content-length").should be_false
    response.headers.has_key?("content-type").should be_false
  end

  def test_prepare_cache_request_last_modified : Nil
    now = Time.utc

    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"if-modified-since" => HTTP.format_time(now)}
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif", headers: HTTP::Headers{"accept-ranges" => "foo", "last-modified" => HTTP.format_time(now)}

    response.prepare request

    response.status.should eq HTTP::Status::NOT_MODIFIED
    response.headers.has_key?("date").should be_true
    response.headers.has_key?("content-length").should be_false
    response.headers.has_key?("content-type").should be_false
  end

  @[DataProvider("ranges")]
  def test_requests(request_range : String, offset : Int32, length : Int32, response_range : String) : Nil
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif", auto_etag: true

    # Request to get ETag
    request = ATH::Request.new "GET", "/"
    response.prepare request
    etag = response.headers["etag"]

    # Request for a range of test file
    request = ATH::Request.new "GET", "/", HTTP::Headers{"if-range" => etag, "range" => request_range}

    expected_output = ::File.open("#{__DIR__}/assets/test.gif", &.read_at(offset, length, &.gets_to_end))

    response.prepare request
    output = String.build do |io|
      response.write io
    end

    output.should eq expected_output
    response.status.should eq HTTP::Status::PARTIAL_CONTENT
    response.headers["content-range"]?.should eq response_range
    response.headers["content-length"]?.should eq length.to_s
  end

  @[DataProvider("ranges")]
  def test_requests_without_etag(request_range : String, offset : Int32, length : Int32, response_range : String) : Nil
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif"

    # Request to get LastModified
    request = ATH::Request.new "GET", "/"
    response.prepare request
    last_modified = response.headers["last-modified"]

    # Request for a range of test file
    request = ATH::Request.new "GET", "/", HTTP::Headers{"if-range" => last_modified, "range" => request_range}

    expected_output = ::File.open("#{__DIR__}/assets/test.gif", &.read_at(offset, length, &.gets_to_end))

    response.prepare request
    output = String.build do |io|
      response.write io
    end

    output.should eq expected_output
    response.status.should eq HTTP::Status::PARTIAL_CONTENT
    response.headers["content-range"]?.should eq response_range
  end

  def ranges : Tuple
    {
      {"bytes=1-4", 1, 4, "bytes 1-4/35"},
      {"bytes=-5", 30, 5, "bytes 30-34/35"},
      {"bytes=30-", 30, 5, "bytes 30-34/35"},
      {"bytes=30-30", 30, 1, "bytes 30-30/35"},
      {"bytes=30-34", 30, 5, "bytes 30-34/35"},
      {"bytes=30-40", 30, 5, "bytes 30-34/35"},
    }
  end

  @[DataProvider("full_file_ranges")]
  def test_full_file_requests(request_range : String) : Nil
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif", auto_etag: true
    request = ATH::Request.new "GET", "/", HTTP::Headers{"range" => request_range}

    expected_output = ::File.open "#{__DIR__}/assets/test.gif", &.read_string(35)

    response.prepare request

    output = String.build do |io|
      response.write io
    end

    output.should eq expected_output
    response.status.should eq HTTP::Status::OK
  end

  def full_file_ranges : Tuple
    {
      {"bytes=0-"},
      {"bytes=0-34"},
      {"bytes=-35"},
      # Syntactical invalid range-request should also return the full resource
      {"bytes=20-10"},
      {"bytes=50-40"},
      # range units other than bytes must be ignored
      {"unknown=10-20"},
    }
  end

  @[DataProvider("invalid_ranges")]
  def test_invalid_requests(request_range : String) : Nil
    response = ATH::BinaryFileResponse.new "#{__DIR__}/assets/test.gif", auto_etag: true
    request = ATH::Request.new "GET", "/", HTTP::Headers{"range" => request_range}

    response.prepare request
    response.write IO::Memory.new

    response.status.should eq HTTP::Status::RANGE_NOT_SATISFIABLE
    response.headers["content-range"]?.should eq "bytes */35"
  end

  def invalid_ranges : Tuple
    {
      {"bytes=-40"},
      {"bytes=40-50"},
    }
  end

  def test_content_disposition_to_s : Nil
    ATH::BinaryFileResponse::ContentDisposition::Attachment.to_s.should eq "attachment"
    ATH::BinaryFileResponse::ContentDisposition::Inline.to_s.should eq "inline"
  end
end
