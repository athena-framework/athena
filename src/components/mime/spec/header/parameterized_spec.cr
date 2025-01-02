struct ParameterizedHeaderTest < ASPEC::TestCase
  @lang = "en-us"

  def test_value_is_returned_verbatim : Nil
    header = AMIME::Header::Parameterized.new "content-type", "text/plain"
    header.body.should eq "text/plain"
  end

  def test_parameters_are_appended : Nil
    header = AMIME::Header::Parameterized.new "content-type", "text/plain"
    header["charset"] = "UTF-8"
    header.body_to_s.should eq "text/plain; charset=UTF-8"
  end

  def test_space_in_param_results_in_quoted_string : Nil
    header = AMIME::Header::Parameterized.new "content-type", "attachment"
    header["filename"] = "my file.txt"
    header.body_to_s.should eq "attachment; filename=\"my file.txt\""
  end

  def test_form_data_results_in_quoted_string : Nil
    header = AMIME::Header::Parameterized.new "content-disposition", "form-data"
    header["filename"] = "file.txt"
    header.body_to_s.should eq "form-data; filename=\"file.txt\""
  end

  def test_form_data_utf8 : Nil
    header = AMIME::Header::Parameterized.new "content-disposition", "form-data"
    header["filename"] = "déjà%\"\n\r.txt"
    header.body_to_s.should eq "form-data; filename=\"déjà%%22%0A%0D.txt\""
  end

  def test_long_params_are_broken_into_multiple_attribute_strings : Nil
    value = "a" * 180

    header = AMIME::Header::Parameterized.new "content-disposition", "attachment"
    header["filename"] = value
    header.body_to_s.should eq(
      "attachment; " \
      "filename*0*=UTF-8''#{"a" * 60};\r\n " \
      "filename*1*=#{"a" * 60};\r\n " \
      "filename*2*=#{"a" * 60}"
    )
  end

  def test_encoded_param_data_includes_charset_and_language : Nil
    value = %(#{"a" * 20}\x8F#{"a" * 10})

    header = AMIME::Header::Parameterized.new "content-disposition", "attachment"
    header.charset = "iso-8859-1"
    header.body = "attachment"
    header["filename"] = value
    header.lang = @lang

    header.body_to_s.should eq "attachment; filename*=iso-8859-1'en-us'aaaaaaaaaaaaaaaaaaaa%8Faaaaaaaaaa"
  end

  def test_multiple_encoded_param_lines_are_formatted_correctly : Nil
    value = %(#{"a" * 20}\x8F#{"a" * 60})

    header = AMIME::Header::Parameterized.new "content-disposition", "attachment"
    header.charset = "UTF-6"
    header.body = "attachment"
    header["filename"] = value
    header.lang = @lang

    header.body_to_s.should eq "attachment; filename*0*=UTF-6'en-us'aaaaaaaaaaaaaaaaaaaa%8Faaaaaaaaaaaaaaaaaaaaaaa;\r\n filename*1*=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  end

  def test_to_s : Nil
    header = AMIME::Header::Parameterized.new "content-type", "text/html"
    header["charset"] = "UTF-8"
    header.to_s.should eq "content-type: text/html; charset=UTF-8"
  end

  def test_value_can_be_encoded_if_not_ascii : Nil
    value = "fo\x8Fbar"
    header = AMIME::Header::Parameterized.new "x-foo", value
    header.charset = "iso-8859-1"
    header["lookslike"] = "foobar"
    header.to_s.should eq "x-foo: =?iso-8859-1?Q?fo=8Fbar?=; lookslike=foobar"
  end

  def test_value_and_param_can_be_encoded_if_not_ascii : Nil
    value = "fo\x8Fbar"
    header = AMIME::Header::Parameterized.new "x-foo", value
    header.charset = "iso-8859-1"
    header["says"] = value
    header.to_s.should eq "x-foo: =?iso-8859-1?Q?fo=8Fbar?=; says*=iso-8859-1''fo%8Fbar"
  end

  def test_param_are_encoded_if_not_ascii : Nil
    value = "fo\x8Fbar"
    header = AMIME::Header::Parameterized.new "x-foo", "bar"
    header.charset = "iso-8859-1"
    header["says"] = value
    header.to_s.should eq "x-foo: bar; says*=iso-8859-1''fo%8Fbar"
  end

  def test_params_are_encoded_with_legacy_encoding_enabled : Nil
    value = "fo\x8Fbar"
    header = AMIME::Header::Parameterized.new "content-type", "bar"
    header.charset = "iso-8859-1"
    header["says"] = value
    header.to_s.should eq %(content-type: bar; says="=?iso-8859-1?Q?fo=8Fbar?=")
  end

  def test_language_information_appears_in_encoded_words : Nil
    value = "fo\x8Fbar"
    header = AMIME::Header::Parameterized.new "x-foo", value
    header.charset = "iso-8859-1"
    header.lang = "en"
    header["says"] = value
    header.to_s.should eq "x-foo: =?iso-8859-1*en?Q?fo=8Fbar?=; says*=iso-8859-1'en'fo%8Fbar"
  end

  def test_set_body : Nil
    header = AMIME::Header::Parameterized.new "content-type", "text/html"
    header.body = "text/plain"
    header.body.should eq "text/plain"
  end
end
