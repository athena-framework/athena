struct FileTest < ASPEC::TestCase
  def test_initialize_non_existent_file : Nil
    ex = expect_raises ::ATH::Exception::FileNotFound, "The file does not exist." do
      ATH::File.new "#{__DIR__}/assets/missing"
    end

    ex.file.should eq "#{__DIR__}/assets/missing"
  end

  def test_mime_type : Nil
    file = ATH::File.new "#{__DIR__}/assets/test.gif"
    file.mime_type.should eq "image/gif"
  end

  def test_guess_extension_unknown : Nil
    file = ATH::File.new "#{__DIR__}/assets/directory/.empty"
    file.guess_extension.should be_nil
  end

  def test_guess_extension_known : Nil
    pending! "MIME guessing is not available" if {{ flag?("windows") && !flag?("gnu") }}

    file = ATH::File.new "#{__DIR__}/assets/test"
    file.guess_extension.should eq "gif"
  end

  def test_move : Nil
    path = "#{Dir.tempdir}/test.copy.gif"
    target_dir = "#{Dir.tempdir}/test"
    target_path = "#{target_dir}/test.copy.gif"
    ::File.delete? path
    ::File.delete? target_path
    ::File.copy "#{__DIR__}/assets/test.gif", path
    Dir.mkdir target_dir unless Dir.exists? target_dir

    file = ATH::File.new path
    moved_file = file.move target_dir
    moved_file.should be_a ATH::File

    ::File.exists?(target_path).should be_true
    ::File.exists?(path).should be_false
    ::File.realpath(target_path).should eq moved_file.realpath

    FileUtils.rm_rf target_dir
  end

  def test_move_new_name : Nil
    path = "#{Dir.tempdir}/test.copy.gif"
    target_dir = "#{Dir.tempdir}/test"
    target_path = "#{target_dir}/test.new.gif"
    ::File.delete? path
    ::File.delete? target_path
    ::File.copy "#{__DIR__}/assets/test.gif", path
    Dir.mkdir target_dir unless Dir.exists? target_dir

    file = ATH::File.new path
    moved_file = file.move target_dir, "test.new.gif"

    ::File.exists?(target_path).should be_true
    ::File.exists?(path).should be_false
    ::File.realpath(target_path).should eq moved_file.realpath

    FileUtils.rm_rf target_dir
  end

  def test_move_non_existent_directory : Nil
    path = "#{Dir.tempdir}/test.copy.gif"
    target_dir = "#{Dir.tempdir}/test"
    target_path = "#{target_dir}/test.copy.gif"
    ::File.delete? path
    ::File.delete? target_path
    ::File.copy "#{__DIR__}/assets/test.gif", path
    FileUtils.rm_rf target_dir

    file = ATH::File.new path
    moved_file = file.move target_dir
    moved_file.should be_a ATH::File

    ::File.exists?(target_path).should be_true
    ::File.exists?(path).should be_false
    ::File.realpath(target_path).should eq moved_file.realpath

    FileUtils.rm_rf target_dir
  end

  @[TestWith(
    {"original.gif", "original.gif"},
    {"..\\..\\original.gif", "original.gif"},
    {"../../original.gif", "original.gif"},

    {"файлfile.gif", "файлfile.gif"},
    {"..\\..\\файлfile.gif", "файлfile.gif"},
    {"../../файлfile.gif", "файлfile.gif"},
  )]
  def test_move_non_latin_names(filename : String, sanitized_filename : String) : Nil
    path = "#{Dir.tempdir}/#{sanitized_filename}"
    target_dir = "#{Dir.tempdir}/test"
    target_path = "#{target_dir}/#{sanitized_filename}"
    ::File.delete? path
    ::File.delete? target_path
    ::File.copy "#{__DIR__}/assets/test.gif", path
    Dir.mkdir target_dir unless Dir.exists? target_dir

    file = ATH::File.new path
    moved_file = file.move target_dir, filename

    ::File.exists?(target_path).should be_true
    ::File.exists?(path).should be_false
    ::File.realpath(target_path).should eq moved_file.realpath

    FileUtils.rm_rf target_dir
  end

  def test_realpath : Nil
    ATH::File.new("#{__DIR__}/../spec/assets/foo.txt").realpath.should eq Path[__DIR__, "assets", "foo.txt"].to_s
  end

  def test_basename : Nil
    ATH::File.new("#{__DIR__}/assets/foo.txt").basename.should eq "foo.txt"
    ATH::File.new("#{__DIR__}/assets/foo.txt").basename(".txt").should eq "foo"
  end

  def test_content : Nil
    ATH::File.new(__FILE__).content.should eq ::File.read __FILE__
  end
end
