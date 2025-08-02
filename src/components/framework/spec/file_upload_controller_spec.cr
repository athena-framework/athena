require "./spec_helper"

struct FileUploadControllerTest < ATH::Spec::APITestCase
  def test_required_single_file_present : Nil
    self.upload_file "/required_single_file_present"

    self.assert_response_is_successful
  end

  def test_optional_single_file_present : Nil
    self.upload_file "/optional_single_file_present"

    self.assert_response_is_successful
  end

  def test_required_single_file_missing : Nil
    self.upload_file "/required_single_file_missing", "missing"

    self.assert_response_has_status :internal_server_error
    URI.decode(self.response.headers["x-debug-exception-message"]).should contain "requires that you provide a value for the 'file' parameter."
  end

  def test_optional_single_file_missing : Nil
    self.upload_file "/optional_single_file_missing"

    self.assert_response_is_successful
  end

  def test_required_single_file_missing_with_constraint : Nil
    self.upload_file "/required_single_file_missing_with_constraint", "missing"

    self.assert_response_has_status :internal_server_error
    URI.decode(self.response.headers["x-debug-exception-message"]).should contain "requires that you provide a value for the 'file' parameter."
  end

  def test_optional_single_file_missing_with_constraint : Nil
    self.upload_file "/optional_single_file_missing_with_constraint", "missing"

    self.assert_response_is_successful
  end

  def test_required_array_present : Nil
    self.upload_file "/required_array_present"

    self.assert_response_is_successful
  end

  def test_optional_array_present : Nil
    self.upload_file "/optional_array_present"

    self.assert_response_is_successful
  end

  def test_required_array_empty : Nil
    self.upload_file "/required_array_empty"

    self.assert_response_is_successful
  end

  def test_optional_array_empty : Nil
    self.upload_file "/optional_array_empty"

    self.assert_response_is_successful
  end

  private def upload_file(route : String, name : String = "file") : Nil
    self.post(
      route,
      headers: HTTP::Headers{
        "content-type" => "multipart/form-data; boundary=\"boundary\"",
      },
      body: self.build_payload name
    )
  end

  private def build_payload(name : String = "file") : String
    String.build do |io|
      HTTP::FormData.build io, "boundary" do |form|
        form.file(
          name,
          File.open("#{__DIR__}/assets/foo.txt"),
          HTTP::FormData::FileMetadata.new(
            "foo.txt"
          ),
          headers: HTTP::Headers{
            "content-type" => "text/plain",
          }
        )
      end
    end
  end
end
