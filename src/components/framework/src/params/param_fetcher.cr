require "./param_fetcher_interface"

@[ADI::Register]
@[ADI::AsAlias]
# Basic implementation of `ATH::Params::ParamFetcherInterface`.
#
# WARNING: May only be used _after_ the related `ATH::Action` has been resolved.
class Athena::Framework::Params::ParamFetcher
  include Athena::Framework::Params::ParamFetcherInterface

  private getter params : Hash(String, ATH::Params::ParamInterface) do
    self.request.action.params.each_with_object({} of String => ATH::Params::ParamInterface) do |param, params|
      params[param.name] = param
    end
  end

  def initialize(
    @request_store : ATH::RequestStore,
    @validator : AVD::Validator::ValidatorInterface
  )
  end

  def each(strict : Bool? = nil, &) : Nil
  end

  # :inherit:
  def each(strict : Bool? = nil, &) : Nil
    self.params.each_key do |key|
      yield key, self.get(key, strict)
    end
  end

  # :inherit:
  def get(name : String, strict : Bool? = nil)
    param = self.params.fetch(name) { raise KeyError.new "Unknown parameter '#{name}'." }

    default = param.default

    self.validate_param(
      param,
      param.extract_value(self.request, default),
      strict.nil? ? param.strict? : strict,
      default
    )
  end

  private def validate_param(param : ATH::Params::ParamInterface, value : _, strict : Bool, default : _)
    self.check_not_incompatible_params param

    begin
      value = param.type.from_parameter value
    rescue ex : ArgumentError
      # Catch type cast errors and bubble it up as an BadRequest if strict
      raise ATH::Exceptions::BadRequest.new "Required parameter '#{param.name}' with value '#{value}' could not be converted into a valid '#{param.type}'.", cause: ex if strict
      return default
    end

    return value if !default.nil? && default == value
    return value if (constraints = param.constraints).empty?

    begin
      # Manually start the context so we can set the base path to the param's name.
      errors = @validator.start_context(value).at_path(param.name).validate(value, constraints).violations
    rescue ex : AVD::Exceptions::ValidatorError
      violation = AVD::Violation::ConstraintViolation.new(
        ex.message || "Unhandled exception while validating '#{param.name}' param.",
        ex.message || "Unhandled exception while validating '#{param.name}' param.",
        Hash(String, String).new,
        value,
        "",
        AVD::ValueContainer.new(value),
      )

      errors = AVD::Violation::ConstraintViolationList.new [violation] of AVD::Violation::ConstraintViolationInterface
    end

    unless errors.empty?
      raise ATH::Exceptions::InvalidParameter.with_violations param, errors if strict
      return default
    end

    value
  end

  private def check_not_incompatible_params(param : ATH::Params::ParamInterface) : Nil
    return if param.extract_value(self.request, nil).nil?
    return unless incompatibles = param.incompatibles

    incompatibles.each do |incompatible_param_name|
      incompatible_param = self.params.fetch(incompatible_param_name) { raise KeyError.new "Unknown parameter '#{incompatible_param_name}'." }

      unless incompatible_param.extract_value(self.request, nil).nil?
        raise ATH::Exceptions::BadRequest.new "Parameter '#{param.name}' is incompatible with parameter '#{incompatible_param.name}'."
      end
    end
  end

  private def request : ATH::Request
    @request_store.request
  end
end
