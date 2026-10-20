require "../spec_helper"

private record Point, x : Int32, y : Int32 do
  include JSON::Serializable
end

private def loaded_bag(json : String = %({"hello":"world","always":"be happy","user.login":"drak","csrf.token":{"a":"1234","b":"4321"}})) : AHTTP::Session::AttributeBag
  AHTTP::Session::AttributeBag.new.tap &.load(JSON::PullParser.new json)
end

struct AHTTP::Session::AttributeBagTest < ASPEC::TestCase
  def test_load : Nil
    bag = AHTTP::Session::AttributeBag.new
    bag.load JSON::PullParser.new %({"hello":"world"})
    bag.all.should eq({"hello" => %("world")})

    bag.load nil
    bag.all.should be_empty
  end

  def test_storage_key : Nil
    AHTTP::Session::AttributeBag.new.storage_key.should eq "_athena_attributes"
    AHTTP::Session::AttributeBag.new("test").storage_key.should eq "test"
  end

  def test_name : Nil
    bag = AHTTP::Session::AttributeBag.new
    bag.name.should eq "attributes"

    bag.name = "foo"
    bag.name.should eq "foo"
  end

  def test_has : Nil
    bag = loaded_bag

    bag.has?("hello").should be_true
    bag.has?("user.login").should be_true
    bag.has?("csrf.token").should be_true
    bag.has?("foo").should be_false
  end

  def test_get : Nil
    bag = loaded_bag

    bag.get("hello", String).should eq "world"
    bag.get("csrf.token", Hash(String, String)).should eq({"a" => "1234", "b" => "4321"})

    expect_raises KeyError, "No session attribute exists with the name 'foo'." do
      bag.get "foo", String
    end
  end

  def test_get? : Nil
    bag = loaded_bag

    bag.get?("hello", String).should eq "world"
    bag.get?("foo", String).should be_nil
  end

  def test_set : Nil
    bag = AHTTP::Session::AttributeBag.new
    bag.set "int", 1
    bag.set "array", [1, 2]
    bag.set "point", Point.new(1, 2)

    bag.get("int", Int32).should eq 1
    bag.get("array", Array(Int32)).should eq [1, 2]
    bag.get("point", Point).should eq Point.new(1, 2)
  end

  def test_all : Nil
    loaded_bag.all.should eq({
      "hello"      => %("world"),
      "always"     => %("be happy"),
      "user.login" => %("drak"),
      "csrf.token" => %({"a":"1234","b":"4321"}),
    })
  end

  def test_remove : Nil
    bag = loaded_bag
    bag.remove "hello"
    bag.remove "foo"

    bag.has?("hello").should be_false
    bag.has?("always").should be_true
  end

  def test_clear : Nil
    bag = loaded_bag
    bag.clear

    bag.empty?.should be_true
  end

  def test_empty : Nil
    bag = AHTTP::Session::AttributeBag.new
    bag.empty?.should be_true

    bag.set "foo", "bar"
    bag.empty?.should be_false
  end

  def test_to_json_embeds_the_values : Nil
    bag = AHTTP::Session::AttributeBag.new
    bag.set "point", Point.new(1, 2)

    JSON.build { |builder| bag.to_json builder }.should eq %({"point":{"x":1,"y":2}})
  end
end
