# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.19.0

### Change how framework features are configured

This change is a pretty fundamental change and cannot really be easily captured in this upgrading guide. Instead, take a moment to review the updated [Configuration](https://athenaframework.org/getting_started/configuration/) section in the getting started guide.

At a high level, the `.configure` calls have been replaced with `ATH.configure` that handles both configuration and parameters.
