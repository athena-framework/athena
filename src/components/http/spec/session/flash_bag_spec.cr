require "../spec_helper"

private def loaded_bag : AHTTP::Session::FlashBag
  AHTTP::Session::FlashBag.new.tap &.load(JSON::PullParser.new %({"notice":["A previous flash message"]}))
end

struct AHTTP::Session::FlashBagTest < ASPEC::TestCase
  def test_load : Nil
    bag = AHTTP::Session::FlashBag.new
    bag.load JSON::PullParser.new %({"notice":["A previous flash message"]})
    bag.peek_all.should eq({"notice" => ["A previous flash message"]})

    bag.load nil
    bag.peek_all.should be_empty
  end

  def test_storage_key : Nil
    AHTTP::Session::FlashBag.new.storage_key.should eq "_athena_flashes"
    AHTTP::Session::FlashBag.new("test").storage_key.should eq "test"
  end

  def test_name : Nil
    bag = AHTTP::Session::FlashBag.new
    bag.name.should eq "flashes"

    bag.name = "foo"
    bag.name.should eq "foo"
  end

  def test_peek : Nil
    bag = loaded_bag

    bag.peek("non_existing").should be_empty
    bag.peek("non_existing", ["default"]).should eq ["default"]
    bag.peek("notice").should eq ["A previous flash message"]
    bag.peek("notice").should eq ["A previous flash message"]
  end

  def test_add : Nil
    bag = loaded_bag
    bag.add "string_message", "lorem"
    bag.add "notice", "Another flash message"

    bag.peek("string_message").should eq ["lorem"]
    bag.peek("notice").should eq ["A previous flash message", "Another flash message"]
  end

  def test_get : Nil
    bag = loaded_bag

    bag.get("non_existing").should be_empty
    bag.get("non_existing", ["default"]).should eq ["default"]
    bag.get("notice").should eq ["A previous flash message"]
    bag.get("notice").should be_empty
  end

  def test_all : Nil
    bag = loaded_bag
    bag.set "notice", "Foo"
    bag.set "error", "Bar"

    bag.all.should eq({"notice" => ["Foo"], "error" => ["Bar"]})
    bag.all.should be_empty
  end

  def test_set : Nil
    bag = loaded_bag
    bag.set "notice", "Foo"
    bag.set "notice", "Bar"
    bag.peek("notice").should eq ["Bar"]

    bag.set "notice", ["Foo", "Bar"]
    bag.peek("notice").should eq ["Foo", "Bar"]
  end

  def test_has : Nil
    bag = loaded_bag

    bag.has?("nothing").should be_false
    bag.has?("notice").should be_true

    bag.set "notice", [] of String
    bag.has?("notice").should be_false
  end

  def test_keys : Nil
    loaded_bag.keys.should eq ["notice"]
  end

  def test_set_all : Nil
    bag = loaded_bag
    bag.add "one_flash", "Foo"
    bag.add "another_flash", "Bar"
    bag.has?("one_flash").should be_true
    bag.has?("another_flash").should be_true

    bag.set_all({"unique_flash" => ["FooBar"]})
    bag.has?("one_flash").should be_false
    bag.has?("another_flash").should be_false
    bag.peek_all.should eq({"unique_flash" => ["FooBar"]})
  end

  def test_peek_all : Nil
    bag = loaded_bag
    bag.set "notice", "Foo"
    bag.set "error", "Bar"

    bag.peek_all.should eq({"notice" => ["Foo"], "error" => ["Bar"]})
    bag.has?("notice").should be_true
    bag.peek_all.should eq({"notice" => ["Foo"], "error" => ["Bar"]})
  end

  def test_clear : Nil
    bag = loaded_bag
    bag.clear

    bag.empty?.should be_true
  end

  def test_to_json : Nil
    JSON.build { |builder| loaded_bag.to_json builder }.should eq %({"notice":["A previous flash message"]})
  end
end
