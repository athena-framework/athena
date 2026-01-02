require "./spec_helper"

struct ParametersTest < ASPEC::TestCase
  # Constructors

  def test_initialize_empty : Nil
    params = ART::Parameters.new
    params.empty?.should be_true
    params.size.should eq 0
  end

  def test_new_from_hash : Nil
    params = ART::Parameters.new({"foo" => "bar", "baz" => "qux"})
    params.size.should eq 2
    params["foo"].should eq "bar"
    params["baz"].should eq "qux"
  end

  def test_new_from_hash_with_different_types : Nil
    params = ART::Parameters.new({"count" => 42, "enabled" => true})
    params.size.should eq 2
    params.get("count", Int32).should eq 42
    params.get("enabled", Bool).should be_true
  end

  def test_new_from_parameters : Nil
    original = ART::Parameters.new({"foo" => "bar"})
    copy = ART::Parameters.new(original)
    copy.should eq original
  end

  # has_key?

  def test_has_key_with_existing_key : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params.has_key?("foo").should be_true
  end

  def test_has_key_with_missing_key : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params.has_key?("missing").should be_false
  end

  def test_has_key_empty : Nil
    params = ART::Parameters.new
    params.has_key?("anything").should be_false
  end

  # []? (returns String?)

  def test_bracket_question_with_string_value : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params["foo"]?.should eq "bar"
  end

  def test_bracket_question_with_missing_key : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params["missing"]?.should be_nil
  end

  def test_bracket_question_with_non_string_value : Nil
    params = ART::Parameters.new
    params["count"] = 42
    params["count"]?.should be_nil
  end

  # [] (returns String, raises KeyError)

  def test_bracket_with_string_value : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params["foo"].should eq "bar"
  end

  def test_bracket_with_missing_key : Nil
    params = ART::Parameters.new
    expect_raises(KeyError, "No parameter exists with the name 'missing'.") do
      params["missing"]
    end
  end

  def test_bracket_with_non_string_value : Nil
    params = ART::Parameters.new
    params["count"] = 42
    expect_raises(TypeCastError) do
      params["count"]
    end
  end

  # raw?

  def test_raw_with_string_value : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params.raw?("foo").should eq "bar"
  end

  def test_raw_with_int_value : Nil
    params = ART::Parameters.new
    params["count"] = 42
    params.raw?("count").should eq 42
  end

  def test_raw_with_bool_value : Nil
    params = ART::Parameters.new
    params["enabled"] = true
    params.raw?("enabled").should be_true
  end

  def test_raw_with_missing_key : Nil
    params = ART::Parameters.new
    params.raw?("missing").should be_nil
  end

  # get? (typed retrieval, returns T?)

  def test_get_question_with_correct_type : Nil
    params = ART::Parameters.new
    params["count"] = 42
    params.get?("count", Int32).should eq 42
  end

  def test_get_question_with_wrong_type : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params.get?("foo", Int32).should be_nil
  end

  def test_get_question_with_missing_key : Nil
    params = ART::Parameters.new
    params.get?("missing", String).should be_nil
  end

  def test_get_question_string : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params.get?("foo", String).should eq "bar"
  end

  # get (typed retrieval, raises KeyError)

  def test_get_with_correct_type : Nil
    params = ART::Parameters.new
    params["count"] = 42
    params.get("count", Int32).should eq 42
  end

  def test_get_with_missing_key : Nil
    params = ART::Parameters.new
    expect_raises(KeyError, "No parameter exists with the name 'missing'.") do
      params.get("missing", Int32)
    end
  end

  def test_get_with_wrong_type : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    expect_raises(TypeCastError) do
      params.get("foo", Int32)
    end
  end

  # keys

  def test_keys : Nil
    params = ART::Parameters.new({"foo" => "bar", "baz" => "qux"})
    params.keys.should eq ["foo", "baz"]
  end

  def test_keys_empty : Nil
    params = ART::Parameters.new
    params.keys.should be_empty
  end

  # empty?

  def test_empty_true : Nil
    params = ART::Parameters.new
    params.empty?.should be_true
  end

  def test_empty_false : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params.empty?.should be_false
  end

  # size

  def test_size_empty : Nil
    params = ART::Parameters.new
    params.size.should eq 0
  end

  def test_size_with_values : Nil
    params = ART::Parameters.new({"a" => "1", "b" => "2", "c" => "3"})
    params.size.should eq 3
  end

  # []=

  def test_set_string_value : Nil
    params = ART::Parameters.new
    params["foo"] = "bar"
    params["foo"].should eq "bar"
  end

  def test_set_int_value : Nil
    params = ART::Parameters.new
    params["count"] = 42
    params.get("count", Int32).should eq 42
  end

  def test_set_overwrites_existing : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params["foo"] = "updated"
    params["foo"].should eq "updated"
  end

  def test_set_nil_value : Nil
    params = ART::Parameters.new
    params["nullable"] = nil
    params.raw?("nullable").should be_nil
    params.has_key?("nullable").should be_true
  end

  # delete

  def test_delete_existing_key : Nil
    params = ART::Parameters.new({"foo" => "bar", "baz" => "qux"})
    params.delete("foo")
    params.has_key?("foo").should be_false
    params.size.should eq 1
  end

  def test_delete_missing_key : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    params.delete("missing")
    params.size.should eq 1
  end

  # merge!

  def test_merge : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    other = ART::Parameters.new({"baz" => "qux"})
    result = params.merge!(other)
    result.should eq params
    params["foo"].should eq "bar"
    params["baz"].should eq "qux"
    params.size.should eq 2
  end

  def test_merge_overwrites : Nil
    params = ART::Parameters.new({"foo" => "original"})
    other = ART::Parameters.new({"foo" => "updated"})
    params.merge!(other)
    params["foo"].should eq "updated"
  end

  def test_merge_nil : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    result = params.merge!(nil)
    result.should eq params
    params.size.should eq 1
  end

  # each

  def test_each : Nil
    params = ART::Parameters.new({"foo" => "bar", "baz" => "qux"})
    collected = {} of String => String
    params.each do |key, value|
      collected[key] = value.as(String)
    end
    collected.should eq({"foo" => "bar", "baz" => "qux"})
  end

  def test_each_with_different_types : Nil
    params = ART::Parameters.new
    params["name"] = "test"
    params["count"] = 42
    keys = [] of String
    params.each do |key, _|
      keys << key
    end
    keys.should eq ["name", "count"]
  end

  # dup

  def test_dup : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    copy = params.dup
    copy["foo"].should eq "bar"
    copy["new"] = "value"
    params.has_key?("new").should be_false
  end

  # clone

  def test_clone : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    copy = params.clone
    copy["foo"].should eq "bar"
    copy["new"] = "value"
    params.has_key?("new").should be_false
  end

  # to_h

  def test_to_h_with_strings : Nil
    params = ART::Parameters.new({"foo" => "bar", "baz" => "qux"})
    params.to_h.should eq({"foo" => "bar", "baz" => "qux"})
  end

  def test_to_h_with_non_string_values : Nil
    params = ART::Parameters.new
    params["count"] = 42
    params["enabled"] = true
    hash = params.to_h
    hash["count"].should eq "42"
    hash["enabled"].should eq "true"
  end

  def test_to_h_with_nil_value : Nil
    params = ART::Parameters.new
    params["nullable"] = nil
    hash = params.to_h
    hash["nullable"].should be_nil
  end

  def test_to_h_empty : Nil
    params = ART::Parameters.new
    params.to_h.should be_empty
  end

  # == (Parameters)

  def test_equality_same_values : Nil
    params1 = ART::Parameters.new({"foo" => "bar"})
    params2 = ART::Parameters.new({"foo" => "bar"})
    (params1 == params2).should be_true
  end

  def test_equality_different_values : Nil
    params1 = ART::Parameters.new({"foo" => "bar"})
    params2 = ART::Parameters.new({"foo" => "different"})
    (params1 == params2).should be_false
  end

  def test_equality_different_keys : Nil
    params1 = ART::Parameters.new({"foo" => "bar"})
    params2 = ART::Parameters.new({"baz" => "bar"})
    (params1 == params2).should be_false
  end

  def test_equality_different_sizes : Nil
    params1 = ART::Parameters.new({"foo" => "bar"})
    params2 = ART::Parameters.new({"foo" => "bar", "extra" => "value"})
    (params1 == params2).should be_false
  end

  def test_equality_empty : Nil
    params1 = ART::Parameters.new
    params2 = ART::Parameters.new
    (params1 == params2).should be_true
  end

  # == (Hash)

  def test_equality_with_hash_same : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    (params == {"foo" => "bar"}).should be_true
  end

  def test_equality_with_hash_different : Nil
    params = ART::Parameters.new({"foo" => "bar"})
    (params == {"foo" => "different"}).should be_false
  end

  def test_equality_with_hash_converts_types : Nil
    params = ART::Parameters.new
    params["count"] = 42
    (params == {"count" => "42"}).should be_true
  end
end
