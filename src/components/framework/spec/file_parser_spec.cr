require "./spec_helper"

struct FileParserTest < ASPEC::TestCase
  def test_parse_happy_path : Nil
    file1 : ATH::UploadedFile? = nil
    file2 : ATH::UploadedFile? = nil

    request = new_request(
      body: String.build do |io|
        HTTP::FormData.build io, "boundary" do |form|
          form.field("age", 12)
          form.file(
            "success",
            File.open("#{__DIR__}/assets/foo.txt"),
            HTTP::FormData::FileMetadata.new(
              "foo.txt"
            ),
            headers: HTTP::Headers{
              "content-type" => "text/plain",
            }
          )

          form.file(
            "too_big",
            File.open("#{__DIR__}/assets/file-big.txt"),
            HTTP::FormData::FileMetadata.new(
              "file-big.txt"
            ),
            headers: HTTP::Headers{
              "content-type" => "text/plain",
            }
          )

          # Skipped due to max_uploads == 2
          form.file(
            "skipped",
            File.open("#{__DIR__}/assets/foo.txt"),
            HTTP::FormData::FileMetadata.new(
              "foo.txt"
            ),
            headers: HTTP::Headers{
              "content-type" => "text/plain",
            }
          )
        end
      end,
      headers: HTTP::Headers{
        "content-type" => "multipart/form-data; boundary=\"boundary\"",
      },
    )

    file_parser = self.target
    file_parser.parse request

    request.files.keys.should eq ["success", "too_big"]

    files = request.files["success"]
    files.size.should eq 1
    file1 = files[0]
    file1.status.ok?.should be_true
    file1.client_original_name.should eq "foo.txt"
    file1.client_original_path.should eq "foo.txt"
    file1.client_mime_type.should eq "text/plain"
    file1.path.should match /file_upload\.\w+/
    file_parser.uploaded_file?(file1.path).should be_true

    files = request.files["too_big"]
    files.size.should eq 1
    file2 = files[0]
    file2.status.size_limit_exceeded?.should be_true
    file2.client_original_name.should eq "file-big.txt"
    file2.client_original_path.should eq "file-big.txt"
    file2.client_mime_type.should eq "text/plain"
    file2.path.should be_empty
    file_parser.uploaded_file?(file2.path).should be_false

    request.attributes.get("age", String).should eq "12"

    file_parser.clear

    ::File.exists?(file1.path).should be_false
  ensure
    file1.try { |f| ::File.delete? f.path }
  end

  private def target(max_uploads : Int32 = 2, max_file_size : Int64 = 50) : ATH::FileParser
    ATH::FileParser.new(
      nil,
      max_uploads,
      max_file_size
    )
  end
end
