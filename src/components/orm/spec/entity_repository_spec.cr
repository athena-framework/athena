require "./spec_helper"

# NOTE: only `find`, `find!`, and `find_one_by` are exercised here. `find_by`,
# `find_all`, and `count` delegate to persister methods that aren't yet
# implemented on the Basic persister (tracked as #26 / #32).
struct EntityRepositoryTest < ASPEC::TestCase
  @em : MockEntityManager
  @uow : MockUnitOfWork
  @persister : MockEntityPersister

  def initialize
    @em = MockEntityManager.new(MockConnection.new)
    @uow = MockUnitOfWork.new @em
    @em.uow_mock = @uow
    @persister = MockEntityPersister.new @em, @em.class_metadata(CmsPhonenumber)
    @uow.set_entity_persister CmsPhonenumber, @persister
  end

  def test_find_with_a_scalar_id_wraps_it_into_a_hash_for_the_persister : Nil
    expected = CmsPhonenumber.new
    expected.phonenumber = "555-0001"
    @persister.mock_load_by_id_result = expected

    result = repository.find("555-0001")

    result.should be expected
    @persister.load_by_id_calls.size.should eq 1
    # EntityManager wraps the scalar into `{single_id_field => value}` before
    # forwarding — ensures composite-key entities can stay on the same code path.
    @persister.load_by_id_calls.first.should eq({"phonenumber" => "555-0001"})
  end

  def test_find_returns_nil_when_persister_finds_no_match : Nil
    @persister.mock_load_by_id_result = nil

    repository.find("missing").should be_nil
  end

  def test_find_returns_an_existing_entity_from_the_identity_map_without_hitting_the_persister : Nil
    cached = CmsPhonenumber.new
    cached.phonenumber = "555-0002"
    @uow.register_managed cached, {"phonenumber" => "555-0002"}, {"phonenumber" => "555-0002"}

    result = repository.find("555-0002")

    result.should be cached
    # Identity-map hit short-circuits before the persister gets called.
    @persister.load_by_id_calls.should be_empty
  end

  def test_find_bang_raises_no_result_when_the_entity_is_missing : Nil
    @persister.mock_load_by_id_result = nil

    expect_raises(AORM::Exceptions::NoResult) do
      repository.find!("missing")
    end
  end

  def test_find_one_by_forwards_criteria_and_pins_limit_to_one : Nil
    expected = CmsPhonenumber.new
    expected.phonenumber = "555-0003"
    @persister.mock_load_result = expected

    criteria = {"phonenumber" => "555-0003"}.transform_values &.as(DB::Any | Array(DB::Any))
    result = repository.find_one_by(criteria)

    result.should be expected
    @persister.load_calls.size.should eq 1
    @persister.load_calls.first.criteria["phonenumber"].should eq "555-0003"
    @persister.load_calls.first.limit.should eq 1
  end

  def test_find_one_by_returns_nil_when_persister_finds_no_match : Nil
    @persister.mock_load_result = nil

    criteria = {"phonenumber" => "x"}.transform_values &.as(DB::Any | Array(DB::Any))
    repository.find_one_by(criteria).should be_nil
  end

  def test_find_one_by_with_keyword_args_converts_symbol_keys_to_strings : Nil
    @persister.mock_load_result = nil

    repository.find_one_by(phonenumber: "555-0004")

    @persister.load_calls.first.criteria.has_key?("phonenumber").should be_true
  end

  def test_find_by_forwards_criteria_order_limit_and_offset : Nil
    canned = [build_phone("555-1001"), build_phone("555-1002")] of AORM::Entity
    @persister.mock_load_all_result = canned

    criteria = {"phonenumber" => "555-1001"}.transform_values &.as(DB::Any | Array(DB::Any))
    result = repository.find_by(criteria, {"phonenumber" => "ASC"}, 10, 5)

    result.size.should eq 2
    @persister.load_all_calls.size.should eq 1
    call = @persister.load_all_calls.first
    call.criteria["phonenumber"].should eq "555-1001"
    call.order_by.should eq({"phonenumber" => "ASC"})
    call.limit.should eq 10
    call.offset.should eq 5
  end

  def test_find_by_returns_empty_array_when_persister_finds_no_matches : Nil
    @persister.mock_load_all_result = [] of AORM::Entity

    criteria = {"phonenumber" => "missing"}.transform_values &.as(DB::Any | Array(DB::Any))
    repository.find_by(criteria).should be_empty
  end

  def test_find_by_with_keyword_args_converts_symbol_keys : Nil
    @persister.mock_load_all_result = [] of AORM::Entity

    repository.find_by(phonenumber: "555-K")

    @persister.load_all_calls.first.criteria.has_key?("phonenumber").should be_true
  end

  def test_find_all_calls_load_all_with_no_criteria : Nil
    canned = [build_phone("555-A"), build_phone("555-B"), build_phone("555-C")] of AORM::Entity
    @persister.mock_load_all_result = canned

    result = repository.find_all

    result.size.should eq 3
    # find_all delegates to find_by({}), so the persister sees an empty criteria hash.
    @persister.load_all_calls.first.criteria.should be_empty
  end

  def test_count_forwards_criteria_and_returns_persister_result : Nil
    @persister.mock_count_result = 7

    criteria = {"phonenumber" => "555-X"}.transform_values &.as(DB::Any | Array(DB::Any))
    repository.count(criteria).should eq 7

    @persister.count_calls.size.should eq 1
    @persister.count_calls.first["phonenumber"].should eq "555-X"
  end

  def test_count_with_no_criteria_calls_persister_with_empty_hash : Nil
    @persister.mock_count_result = 42

    repository.count.should eq 42
    @persister.count_calls.first.should be_empty
  end

  def test_count_with_keyword_args_converts_symbol_keys : Nil
    @persister.mock_count_result = 0

    repository.count(phonenumber: "555-K")

    @persister.count_calls.first.has_key?("phonenumber").should be_true
  end

  private def build_phone(number : String) : CmsPhonenumber
    phone = CmsPhonenumber.new
    phone.phonenumber = number
    phone
  end

  private def repository : AORM::EntityRepository(CmsPhonenumber)
    AORM::EntityRepository(CmsPhonenumber).new(@em, @em.class_metadata(CmsPhonenumber))
  end
end
