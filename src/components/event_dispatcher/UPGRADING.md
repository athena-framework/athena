# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.3.0

### Remove `AED::EventListenerInterface`

The `AED::EventListenerInterface` no longer needs included in your event listener types, and can simply be removed. A type with one or more `AEDA::AsEventListener` annotated methods is now all that is required.
