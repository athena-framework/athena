require "../spec_helper"

struct ArrayCollectionTest < ASPEC::TestCase
  def test_size : Nil
    collection = AORM::ArrayCollection(Int32).new

    collection.size.should eq 0

    collection << 1
    collection << 2

    collection.size.should eq 2
  end

  def test_empty? : Nil
    collection = AORM::ArrayCollection(Int32).new

    collection.empty?.should be_true

    collection << 1

    collection.empty?.should be_false
  end

  def test_add_element : Nil
    collection = AORM::ArrayCollection(String).new

    collection << "foo"
    collection << "bar"

    collection.size.should eq 2
    collection[0].should eq "foo"
    collection[1].should eq "bar"
  end

  def test_index_access : Nil
    collection = AORM::ArrayCollection(String).new(["a", "b", "c"])

    collection[0].should eq "a"
    collection[1].should eq "b"
    collection[2].should eq "c"

    collection[3]?.should be_nil
  end

  def test_index_assignment : Nil
    collection = AORM::ArrayCollection(String).new(["a", "b", "c"])

    collection[1] = "x"

    collection[1].should eq "x"
  end

  def test_includes? : Nil
    collection = AORM::ArrayCollection(String).new(["foo", "bar"])

    collection.includes?("foo").should be_true
    collection.includes?("bar").should be_true
    collection.includes?("baz").should be_false
  end

  def test_delete : Nil
    collection = AORM::ArrayCollection(String).new(["a", "b", "c"])

    deleted = collection.delete("b")

    deleted.should eq "b"
    collection.size.should eq 2
    collection.includes?("b").should be_false
    collection.includes?("a").should be_true
    collection.includes?("c").should be_true
  end

  def test_delete_nonexistent : Nil
    collection = AORM::ArrayCollection(String).new(["a", "b"])

    deleted = collection.delete("x")

    deleted.should be_nil
    collection.size.should eq 2
  end

  def test_clear : Nil
    collection = AORM::ArrayCollection(Int32).new([1, 2, 3])

    collection.clear

    collection.size.should eq 0
    collection.empty?.should be_true
  end

  def test_first_and_last : Nil
    collection = AORM::ArrayCollection(String).new(["a", "b", "c"])

    collection.first?.should eq "a"
    collection.last?.should eq "c"
  end

  def test_first_and_last_empty : Nil
    collection = AORM::ArrayCollection(String).new

    collection.first?.should be_nil
    collection.last?.should be_nil
  end

  def test_iteration : Nil
    collection = AORM::ArrayCollection(Int32).new([1, 2, 3])
    result = [] of Int32

    collection.each do |item|
      result << item
    end

    result.should eq [1, 2, 3]
  end

  def test_to_a_returns_copy : Nil
    collection = AORM::ArrayCollection(Int32).new([1, 2, 3])

    result = collection.to_a

    result.should eq [1, 2, 3]

    # Modifying returned array shouldn't affect collection
    result << 4
    result.clear

    collection.size.should eq 3
    collection.to_a.should eq [1, 2, 3]
  end

  def test_construct_from_enumerable : Nil
    set = Set{1, 2, 3}
    collection = AORM::ArrayCollection(Int32).new(set)

    collection.size.should eq 3
    collection.includes?(1).should be_true
    collection.includes?(2).should be_true
    collection.includes?(3).should be_true
  end

  def test_chained_operations : Nil
    collection = AORM::ArrayCollection(Int32).new

    collection << 1 << 2 << 3

    collection.size.should eq 3
    collection.to_a.should eq [1, 2, 3]
  end
end
