require "../spec_helper"
require "./collection_validator_test_case"

private struct HashLikeObject
  include Enumerable({String | Int32, Int32?})

  @data = {} of String => Int32?

  delegate :each, to: @data

  def has_key?(key : String | Int32) : Bool
    @data.has_key? key
  end

  def [](key : String | Int32) : Int32?
    @data[key]
  end

  def []=(key : String | Int32, value : Int32?)
    @data[key] = value
  end
end

struct HashLikeObjectCollectionValidatorTest < CollectionValidatorTestCase
  private def prepare_test_data(contents : Hash)
    collection = HashLikeObject.new

    contents.each do |k, v|
      collection[k] = v
    end

    collection
  end
end
