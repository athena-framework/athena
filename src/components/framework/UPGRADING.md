# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.20.0

### Normalization of Exception types

The namespace exception types live in has changed from `ATH::Exceptions` to `ATH::Exception`.
Any usages of `framework` exception types will need to be updated.

If using a `rescue` statement with a parent exception type, either from the `framework` component or Crystal stdlib, double check it to ensure it'll still rescue what you are expecting it will.

### `ATHR::Interface.configuration` scoping

Previously if you had a value resolver using the `configuration` macro:

```cr
struct Multiply
  include ATHR::Interface

  configuration This

  # ...
end
```

The `This` configuration would be scoped to the `Multiply` namespace, i.e. `@[Multiply::This]`.
Scoping is now handled separately, meaning the same resolver could define multiple configurations to an entirely different namespace.
If you wish to retain the same behavior, provide the FQN to the `configuration` macro: `configuration Multiply::This`.
If you wish to move the configuration to another namespace, prefix the FQN with `::`: `configuration ::MyApp::Annotations::Multiply`.

## Upgrade to 0.19.0

### Change how framework features are configured

This change is a pretty fundamental change and cannot really be easily captured in this upgrading guide. Instead, take a moment to review the updated [Configuration](https://athenaframework.org/getting_started/configuration/) section in the getting started guide.

At a high level, the `.configure` calls have been replaced with `ATH.configure` that handles both configuration and parameters.
