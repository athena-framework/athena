# Changelog

## [0.17.1] - 2022-09-05

## Changed

- **Breaking:** ensure parameter names defined on interfaces match the implementation ([#188](https://github.com/athena-framework/athena/pull/188)) (George Dietrich)

## [0.17.0] - 2022-05-14

_Checkout [this](https://forum.crystal-lang.org/t/athena-0-17-0/4624) forum thread for an overview of changes within the ecosystem._

### Added

- Add `pcre2` library dependency to `shard.yml` ([#159](https://github.com/athena-framework/athena/pull/159)) (George Dietrich)
- Add [ATH::Arguments::Resolvers::Enum](https://athenaframework.org/Framework/Arguments/Resolvers/Enum/) to allow resolving `Enum` members directly to controller actions ([#173](https://github.com/athena-framework/athena/pull/173)) (George Dietrich)
- Add [ATH::Arguments::Resolvers::UUID](https://athenaframework.org/Framework/Arguments/Resolvers/UUID/) to allow resolving `UUID`s directly to controller actions by ([#176](https://github.com/athena-framework/athena/pull/176)) (George Dietrich)
- Add [ATH::ParameterBag#has(name, type)](https://athenaframework.org/Framework/ParameterBag/#Athena::Framework::ParameterBag#has?(name,type)) that checks if a parameter with the provided name exists, and that is of the provided type ([#176](https://github.com/athena-framework/athena/pull/176)) (George Dietrich)
- Add [ATH::Arguments::Resolvers::DefaultValue](https://athenaframework.org/Framework/Arguments/Resolvers/DefaultValue/) to allow resolving an action parameter's default value if no other value was provided ([#177](https://github.com/athena-framework/athena/pull/177)) (George Dietrich)

### Changed

- **Breaking:** rename `ATH::Arguments::Resolvers::ArgumentValueResolverInterface` to `ATH::Arguments::Resolvers::Interface` ([#176](https://github.com/athena-framework/athena/pull/176)) (George Dietrich)
- **Breaking:** bump `athena-framework/serializer` to `~> 0.3.0` ([#181](https://github.com/athena-framework/athena/pull/181)) (George Dietrich)
- **Breaking:** bump `athena-framework/validator` to `~> 0.2.0` ([#181](https://github.com/athena-framework/athena/pull/181)) (George Dietrich)
- Expose the default value of an [ATH::Arguments::ArgumentMetadata](https://athenaframework.org/Framework/Arguments/ArgumentMetadata/) ([#176](https://github.com/athena-framework/athena/pull/176)) (George Dietrich)
- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)

### Fixed

- Fix error when two controller share a common action name ([#146](https://github.com/athena-framework/athena/pull/146)) (George Dietrich)
- Fix release badge to use correct repo ([#161](https://github.com/athena-framework/athena/pull/161)) (George Dietrich)
- Fix query/request param docs to use new error responses ([#167](https://github.com/athena-framework/athena/pull/167)) (George Dietrich)
- Fix incorrect `Athena::Framework` `Log` name ([#175](https://github.com/athena-framework/athena/pull/175)) (George Dietrich)

## [0.16.0] - 2022-01-22

_First release in the [athena-framework/framework](https://github.com/athena-framework/framework) repo, post monorepo._

### Added

- Add dependency on `athena-framework/routing` ([#141](https://github.com/athena-framework/athena/pull/141)) (George Dietrich)
- Allow prepending [HTTP::Handlers](https://crystal-lang.org/api/HTTP/Handler.html) to the Athena server ([#133](https://github.com/athena-framework/athena/pull/133)) (George Dietrich)
- Add common HTTP methods (get, post, put, delete) to [ATH::Spec::APITestCase](https://athenaframework.org//Framework/Spec/APITestCase/#Athena::Framework::Spec::APITestCase-methods) ([#134](https://github.com/athena-framework/athena/pull/134)) (George Dietrich)
- Add overload of [ATH::Spec::APITestCase#request](https://athenaframework.org/Framework/Spec/APITestCase/#Athena::Framework::Spec::APITestCase#request(method,path,body,headers)) that accepts an [ATH::Request](https://athenaframework.org/Framework/Request/) or [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html) ([#134](https://github.com/athena-framework/athena/pull/134)) (George Dietrich)
- Allow running an HTTPS server via passing an [OpenSSL::SSL::Context::Server](https://crystal-lang.org/api/OpenSSL/SSL/Context/Server.html) to `ATH.run` ([#135](https://github.com/athena-framework/athena/pull/135), [#136](https://github.com/athena-framework/athena/pull/136)) (George Dietrich)
- Add [ATH::ParameterBag#set(hash)](https://athenaframework.org/Framework/ParameterBag/#Athena::Framework::ParameterBag#set(name,value,type)) that allows setting a hash of key/value pairs ([#141](https://github.com/athena-framework/athena/pull/141)) (George Dietrich)

### Changed

- **Breaking:** integrate the [Athena::Routing](https://athenaframework.org/Routing/) component ([#141](https://github.com/athena-framework/athena/pull/141)) (George Dietrich)

### Removed

- **Breaking:** remove dependecy on [amberframework/amber-router](https://github.com/amberframework/amber-router) ([#141](https://github.com/athena-framework/athena/pull/141)) (George Dietrich)

## [0.15.1] - 2021-12-13

### Changed

- Include error list in `ATH::Exceptions::InvalidParameter` ([#124](https://github.com/athena-framework/athena/pull/124)) (George Dietrich)
- Set the base path of parameter errors to the name of the parameter ([#124](https://github.com/athena-framework/athena/pull/124)) (George Dietrich)

## [0.15.0] - 2021-10-30

_Last release in the [athena-framework/athena](https://github.com/athena-framework/athena) repo, pre monorepo._

### Added

- Expose the raw [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html) method from an `ATH::Request` ([#115](https://github.com/athena-framework/athena/pull/115)) (George Dietrich)
- Add built in [ATH::RequestBodyConverter](https://athenaframework.org/Framework/RequestBodyConverter) param converter ([#116](https://github.com/athena-framework/athena/pull/116)) (George Dietrich)
- Add `VERSION` constant to `Athena::Framework` namespace ([#120](https://github.com/athena-framework/athena/pull/120)) (George Dietrich)

### Changed

- **Breaking:** rename base param converter type to `ATH::ParamConverter` and make it a class ([#116](https://github.com/athena-framework/athena/pull/116)) (George Dietrich)
- **Breaking:** rename the component from `Athena::Routing` to `Athena::Framework` ([#120](https://github.com/athena-framework/athena/pull/120)) (George Dietrich)

### Fixed

- Fix incorrect parameter type restriction on `ATH::ParameterBag#set` ([#116](https://github.com/athena-framework/athena/pull/116)) (George Dietrich)
- Fix incorrect ivar type on `AVD::Exceptions::Exceptions::ValidationFailed#violations` ([#116](https://github.com/athena-framework/athena/pull/116)) (George Dietrich)
- Correctly reject requests with whitespace when converting numeric inputs ([#117](https://github.com/athena-framework/athena/pull/117)) (George Dietrich)

[0.17.1]: https://github.com/athena-framework/athena/releases/tag/v0.17.1
[0.17.0]: https://github.com/athena-framework/athena/releases/tag/v0.17.0
[0.16.0]: https://github.com/athena-framework/athena/releases/tag/v0.16.0
[0.15.1]: https://github.com/athena-framework/athena/releases/tag/v0.15.1
[0.15.0]: https://github.com/athena-framework/athena/releases/tag/v0.15.0
