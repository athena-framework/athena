The [Validator][Athena::Validator] component adds a robust/flexible validation framework. This component is also mostly optional, but can be super helpful as part of a [param converter](../getting_started/advanced_usage.md#param-converters) to ensure only valid data make it into the system. The [Cookbook](../cookbook/param_converters.md#request-body) has an example of how this could be implemented. This component can also be used to define validation requirements for [ATH::Params::ParamInterface][Athena::Framework::Params::ParamInterface]s.

## Custom Constraints

In addition to the general information for defining [Custom Constraints](../Validator/Constraint#custom-constraints), the validator component defines a specific type for defining service based constraint validators: `AVD::ServiceConstraintValidator`. This type should be inherited from instead of `AVD::ConstraintValidator` _IF_ the validator for your custom constraint needs to be a service, E.x.

```crystal
class Athena::Validator::Constraints::CustomConstraint < AVD::Constraint
  # ...

  @[ADI::Register]
  struct Validator < AVD::ServiceConstraintValidator
    def initialize(...); end

    # :inherit:
    def validate(value : _, constraint : AVD::Constraints::CustomConstraint) : Nil
      # ...
    end
  end
end
```

See the [API Docs][Athena::Validator] documentation for more detailed information, or [this forum post](https://forum.crystal-lang.org/t/athena-0-11-0/2627) for a quick overview.
