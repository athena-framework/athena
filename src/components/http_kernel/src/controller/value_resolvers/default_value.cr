# Resolves the default value of a controller action parameter if no other value was provided;
# using `nil` if the parameter does not have a default value, but is nilable.
#
# ```
# AHK::Controller::ParameterMetadata(Int32).new("id", has_default: true, default_value: 123)
# # resolve would return 123
# ```
struct Athena::HTTPKernel::Controller::ValueResolvers::DefaultValue
  include Athena::HTTPKernel::Controller::ValueResolvers::Interface

  # :inherit:
  def resolve(request : AHTTP::Request, parameter : AHK::Controller::ParameterMetadata)
    return if !parameter.has_default? && !parameter.nilable?

    parameter.default_value?
  end
end
