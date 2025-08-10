require "./spec_helper"

struct UploadedFileTest < ASPEC::TestCase
  def test_initialize_non_existent_file : Nil
    ex = expect_raises ::ATH::Exception::FileNotFound, "The file does not exist." do
      ATH::UploadedFile.new "#{__DIR__}/assets/missing", "original.gif"
    end

    ex.file.should eq "#{__DIR__}/assets/missing"
  end

  def test_no_mime_type : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif"

    file.client_mime_type.should eq "application/octet-stream"
    file.mime_type.should eq "image/gif"
    file.status.ok?.should be_true
  end

  def test_unknown_mime_type : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/.unknownextension", "original.gif"

    file.client_mime_type.should eq "application/octet-stream"
  end

  def test_guess_client_extension : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif"

    file.guess_client_extension.should eq "gif"
  end

  def test_guess_client_extension_with_incorrect_mime_type : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/png"

    file.guess_client_extension.should eq "png"
  end

  def test_case_sensitive_mime_type : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/case-sensitive-mime-type.xlsm", "text.xlsm", "application/vnd.ms-excel.sheet.macroEnabled.12"

    file.guess_client_extension.should eq "xlsm"
  end

  def test_client_original_name : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif"

    file.client_original_name.should eq "original.gif"
  end

  def test_client_original_extension : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif"

    file.client_original_extension.should eq "gif"
  end

  def test_move_local_file_is_not_allowed : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif"

    expect_raises ::ATH::Exception::File, "The file 'original.gif' was not uploaded due to an unknown error." do
      file.move "#{__DIR__}/assets/directory"
    end
  end

  def test_move_local_file_is_allowed_in_test_mode : Nil
    path = "#{Dir.tempdir}/test.copy.gif"
    target_dir = "#{Dir.tempdir}/test"
    target_path = "#{target_dir}/test.copy.gif"
    ::File.delete? path
    ::File.delete? target_path
    ::File.copy "#{__DIR__}/assets/test.gif", path
    Dir.mkdir target_dir unless Dir.exists? target_dir

    file = ATH::UploadedFile.new path, "original.gif", "image/gif", test: true
    moved_file = file.move target_dir
    moved_file.should be_a ATH::File

    ::File.exists?(target_path).should be_true
    ::File.exists?(path).should be_false
    ::File.realpath(target_path).should eq moved_file.realpath

    FileUtils.rm_rf target_dir
  end

  def test_move_failed_too_big : Nil
    ATH::UploadedFile.max_file_size = 1024 * 5
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif", :size_limit_exceeded

    expect_raises ::ATH::Exception::FileSizeLimitExceeded, "The file 'original.gif' exceeds your max_file_size configuration value (limit is 5.0kiB)." do
      file.move "#{__DIR__}/assets/directory"
    end
  ensure
    ATH::UploadedFile.max_file_size = 0
  end

  def test_client_original_name_sanitize_filename : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "../../original.gif", "image/gif"

    file.client_original_name.should eq "original.gif"
  end

  def test_size : Nil
    file = ATH::UploadedFile.new path = "#{__DIR__}/assets/test.gif", "original.gif", "image/gif"
    file.size.should eq File.size path

    file = ATH::UploadedFile.new path = "#{__DIR__}/assets/test", "original.gif", "image/gif"
    file.size.should eq File.size path
  end

  def test_extname : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif"

    file.extname.should eq "gif"
  end

  def test_client_original_path : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif"

    file.client_original_path.should eq "original.gif"
  end

  def test_client_original_path_webkit_directory : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/webkitdirectory/test.txt", "webkitdirectory/test.txt", "text/plain"

    file.client_original_path.should eq "webkitdirectory/test.txt"
  end

  def test_valid : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif", test: true
    file.valid?.should be_true
  end

  def test_invalid : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif", :size_limit_exceeded
    file.valid?.should be_false
  end

  def test_invalid_non_http_upload : Nil
    file = ATH::UploadedFile.new "#{__DIR__}/assets/test.gif", "original.gif", "image/gif"
    file.valid?.should be_false
  end
end
