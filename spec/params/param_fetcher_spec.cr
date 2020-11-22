require "../spec_helper"

struct ParamFetcherTest < ASPEC::TestCase
  @request_store : ART::RequestStore
  @param_fetcher : ART::Params::ParamFetcher
  @valiator : AVD::Spec::MockValidator

  def initialize
    @request_store = ART::RequestStore.new
    @request_store.request = new_request
    @valiator = AVD::Spec::MockValidator.new

    @param_fetcher = ART::Params::ParamFetcher.new @request_store, @valiator
  end

  def test_missing_param : Nil
    expect_raises KeyError, "Unknown parameter 'missing'." do
      @param_fetcher.get "missing"
    end
  end

  def test_get_no_constraints : Nil
    self.set_params [new_param("name", default: "bar")] of ART::Params::ParamInterface

    @request_store.request.query = "name=foo"

    @param_fetcher.get("name").should eq "foo"
  end

  def test_get_missing_with_constraints_uses_default : Nil
    self.set_params [new_param("foo", default: "bar", requirements: AVD::Constraints::NotBlank.new)] of ART::Params::ParamInterface
    @param_fetcher.get("foo").should eq "bar"
  end

  def test_get_no_constraints : Nil
    self.set_params [new_param("foo")] of ART::Params::ParamInterface
    @request_store.request.query = "foo=value"
    @param_fetcher.get("foo").should eq "value"
  end

  def test_get_constraints_no_violations : Nil
    self.set_params [new_param("foo", requirements: AVD::Constraints::NotBlank.new)] of ART::Params::ParamInterface

    @request_store.request.query = "foo=value"

    @param_fetcher.get("foo").should eq "value"
  end

  def test_get_constraints_violations_unstrict : Nil
    self.set_params [new_param("foo", default: "default", requirements: AVD::Constraints::NotBlank.new)] of ART::Params::ParamInterface

    @request_store.request.query = "foo=value"
    @valiator.violations = AVD::Violation::ConstraintViolationList.new [
      AVD::Violation::ConstraintViolation.new(
        "ERROR",
        "ERROR",
        Hash(String, String).new,
        "",
        "",
        AVD::ValueContainer.new(""),
      ),
    ]

    @param_fetcher.get("foo", false).should eq "default"
  end

  def test_get_constraints_violations_strict : Nil
    param = new_param("foo", default: "default", requirements: AVD::Constraints::NotBlank.new)
    self.set_params [param] of ART::Params::ParamInterface

    @request_store.request.query = "foo=value"
    violations = @valiator.violations = AVD::Violation::ConstraintViolationList.new [
      AVD::Violation::ConstraintViolation.new(
        "ERROR",
        "ERROR",
        Hash(String, String).new,
        "",
        "",
        AVD::ValueContainer.new(""),
      ),
    ]

    ex = expect_raises ART::Exceptions::InvalidParameter do
      @param_fetcher.get("foo").should eq "default"
    end

    ex.violations.should eq violations
    ex.parameter.should eq param
  end

  def test_get_conversion_error_strict : Nil
    self.set_params [new_param("foo", default: 10, type: Int32?)] of ART::Params::ParamInterface

    @request_store.request.query = "foo=value"

    expect_raises ART::Exceptions::BadRequest, "Required parameter 'foo' with value 'value' could not be converted into a valid '(Int32 | Nil)'" do
      @param_fetcher.get "foo"
    end
  end

  def test_get_missing_incompatible : Nil
    self.set_params([
      self.new_param("fos"),
      self.new_param("bar", incompatibilities: ["baz", "fos"]),
    ] of ART::Params::ParamInterface)

    @request_store.request.query = "bar=value"

    expect_raises KeyError, "Unknown parameter 'baz'." do
      @param_fetcher.get "bar"
    end
  end

  def test_get_incompatible : Nil
    self.set_params([
      self.new_param("fos"),
      self.new_param("baz"),
      self.new_param("bar", incompatibilities: ["baz", "fos"]),
    ] of ART::Params::ParamInterface)

    @request_store.request.query = "bar=value&fos=value"

    expect_raises ART::Exceptions::BadRequest, "'bar' param is incompatible with 'fos' param." do
      @param_fetcher.get "bar"
    end
  end

  private def set_params(params : Array(ART::Params::ParamInterface)) : Nil
    @request_store.request = new_request(action: new_action(params: params))
  end

  private def new_param(name : String, *, default : String | Int32 | Nil = nil, requirements : AVD::Constraint? = nil, incompatibilities : Array(String)? = nil, type : T.class = String?) : ART::Params::ParamInterface forall T
    ART::Params::QueryParam(T).new(
      name,
      has_default: !default.nil?,
      is_nilable: true,
      key: name,
      default: default,
      requirements: requirements,
      incompatibilities: incompatibilities
    )
  end
end
