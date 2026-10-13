The [Athena::Validator](/Validator) component adds a robust/flexible validation framework.
This component is optional; to use it within the framework, add it to your `shard.yml` and register its [bundle](/Validator/Bundle/) via `require "athena-validator/bundle"`.
It is then leveraged for the super useful [ATHR::RequestBody](/Framework/Controller/ValueResolvers/RequestBody) resolver type to ensure only valid data make it into the system.
This component can also be used to define validation requirements for [ATH::Params::ParamInterface](/Framework/Params/ParamInterface)s.

## Custom Constraints

In addition to the general information for defining [Custom Constraints](/Validator/#Athena::Validator--custom-constraints), the validator component defines a specific type for defining service based constraint validators: `AVD::ServiceConstraintValidator`.
This type should be inherited from instead of `AVD::ConstraintValidator` _IF_ the validator for your custom constraint needs to be a service, E.x.

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
