require "../spec_helper"

struct ClassNameGeneratorTest < ASPEC::TestCase
  def test_name : Nil
    AORM::Migrations::Generator::ClassNameGenerator.new.generate_class_name("App::Migrations").should match /^App::Migrations::Version[0-9]{14}$/
  end
end
