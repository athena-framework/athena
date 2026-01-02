# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.2.0

### New route default/matched route parameter type

Route defaults and matcher return values now use the new `ART::Parameters` type instead of `Hash(String, String?)`.

The new type supports _mostly_ the same API as the old `Hash` type, but may need to update type restrictions if you were passing around the defaults/matched route parameters hash.
Additionally, if implementing a custom URL matcher, update return types from `Hash(String, String?)` to `ART::Parameters`.

## Upgrade to 0.1.9

### New `ART::Generator::Interface` method

If implementing a custom URL Generator, you will now need to implement the following new method:

- `abstract def generate(route : String, reference_type : ART::Generator::ReferenceType = :absolute_path, **params) : String`
