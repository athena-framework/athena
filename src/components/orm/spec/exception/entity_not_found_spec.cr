require "../spec_helper"

struct EntityNotFoundTest < ASPEC::TestCase
  def test_from_class_name_and_identifier : Nil
    exception = AORM::Exception::EntityNotFound.from_class_name_and_identifier "foo", {"foo" => "bar"}
    exception.message.should eq "Entity of type 'foo' for IDs foo(bar) was not found"

    exception = AORM::Exception::EntityNotFound.from_class_name_and_identifier "foo", {} of String => String
    exception.message.should eq "Entity of type 'foo' was not found"
  end

  def test_no_identifier_found : Nil
    exception = AORM::Exception::EntityNotFound.no_identifier_found "foo"
    exception.message.should eq %(Unable to find "foo" entity identifier associated with the UnitOfWork)
  end
end
