# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.1.9

### New `ART::Generator::Interface` method

If implementing a custom URL Generator, you will now need to implement the following new method:

- `abstract def generate(route : String, reference_type : ART::Generator::ReferenceType = :absolute_path, **params) : String`
