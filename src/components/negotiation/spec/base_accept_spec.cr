require "./spec_helper"

private struct MockAccept < ANG::BaseAccept; end

struct BaseAcceptTest < ASPEC::TestCase
  @[DataProvider("build_parameters_data_provider")]
  def test_build_parameters_string(header : String, expected : String) : Nil
    MockAccept.new(header).normalized_header.should eq expected
  end

  def build_parameters_data_provider : Tuple
    {
      {"media/type; xxx = 1.0;level=2;foo=bar", "media/type; foo=bar; level=2; xxx=1.0"},
    }
  end

  @[DataProvider("parameters_data_provider")]
  def test_parse_parameters(header : String, expected_parameters : Hash(String, String)) : Nil
    accept = MockAccept.new header
    parameters = accept.parameters

    # TODO: Can this be improved?
    if header.includes? 'q'
      parameters["q"] = accept.quality.to_s
    end

    expected_parameters.size.should eq parameters.size

    expected_parameters.each do |k, v|
      parameters.has_key?(k).should be_true
      parameters[k].should eq v
    end
  end

  def parameters_data_provider : Tuple
    {
      {
        "application/json ;q=1.0; level=2;foo= bar",
        {
          "q"     => "1.0",
          "level" => "2",
          "foo"   => "bar",
        },
      },
      {
        "application/json ;q = 1.0; level = 2;     FOO  = bAr",
        {
          "q"     => "1.0",
          "level" => "2",
          "foo"   => "bAr",
        },
      },
      {
        "application/json;q=1.0",
        {
          "q" => "1.0",
        },
      },
      {
        "application/json;foo",
        {} of String => String,
      },
    }
  end
end
