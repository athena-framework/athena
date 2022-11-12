require "../spec_helper"

struct ParamFetcherTest < ASPEC::TestCase
  @request_store : ATH::RequestStore
  @param_fetcher : ATH::Params::ParamFetcher
  @validator : AVD::Spec::MockValidator

  def initialize
    @expected_violations = AVD::Violation::ConstraintViolationList.new

    @request_store = ATH::RequestStore.new
    @request_store.request = new_request
    @validator = AVD::Spec::MockValidator.new @expected_violations

    @param_fetcher = ATH::Params::ParamFetcher.new @request_store, @validator
  end

  def test_missing_param : Nil
    expect_raises KeyError, "Unknown parameter 'missing'." do
      @param_fetcher.get "missing"
    end
  end

  def test_get_no_constraints : Nil
    self.set_params [new_param("name", default: "bar")] of ATH::Params::ParamInterface

    @request_store.request.query = "name=foo"

    @param_fetcher.get("name").should eq "foo"
  end

  def test_get_missing_with_constraints_uses_default : Nil
    self.set_params [new_param("foo", default: "bar", requirements: AVD::Constraints::NotBlank.new)] of ATH::Params::ParamInterface
    @param_fetcher.get("foo").should eq "bar"
  end

  def test_get_no_constraints : Nil
    self.set_params [new_param("foo")] of ATH::Params::ParamInterface
    @request_store.request.query = "foo=value"
    @param_fetcher.get("foo").should eq "value"
  end

  def test_get_constraints_no_violations : Nil
    self.set_params [new_param("foo", requirements: AVD::Constraints::NotBlank.new)] of ATH::Params::ParamInterface

    @request_store.request.query = "foo=value"

    @param_fetcher.get("foo").should eq "value"
  end

  def test_get_constraints_violations_unstrict : Nil
    self.set_params [new_param("foo", default: "default", requirements: AVD::Constraints::NotBlank.new)] of ATH::Params::ParamInterface

    @request_store.request.query = "foo=value"
    @expected_violations.add AVD::Violation::ConstraintViolation.new(
      "ERROR",
      "ERROR",
      Hash(String, String).new,
      "",
      "",
      AVD::ValueContainer.new(""),
    )

    @param_fetcher.get("foo", false).should eq "default"
  end

  def test_get_constraints_violations_strict : Nil
    param = new_param("foo", default: "default", requirements: AVD::Constraints::NotBlank.new)
    self.set_params [param] of ATH::Params::ParamInterface

    @request_store.request.query = "foo=value"
    @expected_violations.add AVD::Violation::ConstraintViolation.new(
      "ERROR",
      "ERROR",
      Hash(String, String).new,
      "",
      "",
      AVD::ValueContainer.new(""),
    )

    ex = expect_raises ATH::Exceptions::InvalidParameter do
      @param_fetcher.get("foo").should eq "default"
    end

    ex.violations.should eq @expected_violations
    ex.parameter.should eq param
  end

  def test_get_conversion_error_strict : Nil
    self.set_params [new_param("foo", default: 10, nilable: false, type: Int32)] of ATH::Params::ParamInterface

    @request_store.request.query = "foo=value"

    expect_raises ATH::Exceptions::BadRequest, "Required parameter 'foo' with value 'value' could not be converted into a valid 'Int32'" do
      @param_fetcher.get "foo"
    end
  end

  def test_get_conversion_error_strict_union : Nil
    self.set_params [new_param("foo", default: 10, type: Int32?)] of ATH::Params::ParamInterface
    @request_store.request.query = "foo=value"
    expect_raises ATH::Exceptions::BadRequest, "Required parameter 'foo' with value 'value' could not be converted into a valid '(Int32 | Nil)'" do
      @param_fetcher.get "foo"
    end
  end

  def test_get_conversion_error_unstrict_union : Nil
    self.set_params [new_param("foo", default: 10, type: Int32?)] of ATH::Params::ParamInterface
    @request_store.request.query = "foo=value"
    @param_fetcher.get("foo", false).should eq 10
  end

  def test_get_missing_incompatible : Nil
    self.set_params([
      self.new_param("fos"),
      self.new_param("bar", incompatibles: ["baz", "fos"]),
    ] of ATH::Params::ParamInterface)

    @request_store.request.query = "bar=value"

    expect_raises KeyError, "Unknown parameter 'baz'." do
      @param_fetcher.get "bar"
    end
  end

  def test_get_incompatible : Nil
    self.set_params([
      self.new_param("fos"),
      self.new_param("baz"),
      self.new_param("bar", incompatibles: ["baz", "fos"]),
    ] of ATH::Params::ParamInterface)

    @request_store.request.query = "bar=value&fos=value"

    expect_raises ATH::Exceptions::BadRequest, "Parameter 'bar' is incompatible with parameter 'fos'." do
      @param_fetcher.get "bar"
    end
  end

  def test_all : Nil
    self.set_params([
      self.new_param("foo"),
      self.new_param("bar"),
    ] of ATH::Params::ParamInterface)

    @request_store.request.query = "foo=bar&bar=foo"

    values = [] of String

    @param_fetcher.each do |value|
      values << value
    end

    values.should eq ["foo", "bar"]
  end

  private def set_params(params : Array(ATH::Params::ParamInterface)) : Nil
    @request_store.request = new_request(action: new_action(params: params))
  end

  private def new_param(
    name : String,
    *,
    nilable : Bool = true,
    default : String | Int32 | Nil = nil,
    requirements : AVD::Constraint? = nil,
    incompatibles : Array(String)? = nil,
    type : T.class = String?
  ) : ATH::Params::ParamInterface forall T
    ATH::Params::QueryParam(T).new(
      name,
      has_default: !default.nil?,
      is_nilable: nilable,
      key: name,
      default: default,
      requirements: requirements,
      incompatibles: incompatibles
    )
  end
end
