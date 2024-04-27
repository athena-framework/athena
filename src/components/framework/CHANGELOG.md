# Changelog

## [0.19.1] - 2024-04-27

### Fixed

- Fix `framework` component docs landing on an empty page ([#399](https://github.com/athena-framework/athena/pull/399)) (George Dietrich)
- Fix `Athena::Clock` not being aliased to the interface correctly ([#400](https://github.com/athena-framework/athena/pull/400)) (George Dietrich)
- Fix `ATHA::View` annotation being defined in incorrect namespace ([#403](https://github.com/athena-framework/athena/pull/403)) (George Dietrich)
- Fix `ATH::ErrorRenderer` not being aliased to the interface correctly ([#404](https://github.com/athena-framework/athena/pull/404)) (George Dietrich)

## [0.19.0] - 2024-04-09

### Changed

- **Breaking:** change how framework features are configured ([#337](https://github.com/athena-framework/athena/pull/337), [#374](https://github.com/athena-framework/athena/pull/374), [#383](https://github.com/athena-framework/athena/pull/383)) (George Dietrich)
- Update minimum `crystal` version to `~> 1.11.0` ([#270](https://github.com/athena-framework/athena/pull/270)) (George Dietrich)
- Integrate website into monorepo ([#365](https://github.com/athena-framework/athena/pull/365)) (George Dietrich)

### Added

- Support for Windows OS ([#270](https://github.com/athena-framework/athena/pull/270)) (George Dietrich)
- Add `ATH::RequestMatcher` as a generic way of matching an `ATH::Request` given a set of rules ([#338](https://github.com/athena-framework/athena/pull/338)) (George Dietrich)
- Raise an exception if a controller's return value fails to serialize instead of just returning `nil` ([#357](https://github.com/athena-framework/athena/pull/357)) (George Dietrich)
- Add support for new Crystal 1.12 `Process.on_terminate` method ([#394](https://github.com/athena-framework/athena/pull/394)) (George Dietrich)

### Fixed

- Fix macro splat deprecation ([#330](https://github.com/athena-framework/athena/pull/330)) (George Dietrich)
- Normalize `ATH::Request#method` to always be uppercase ([#338](https://github.com/athena-framework/athena/pull/338)) (George Dietrich)
- Fixed not being able to use top level configuration annotations on controller action parameters ([#356](https://github.com/athena-framework/athena/pull/356)) (George Dietrich)

## [0.18.2] - 2023-10-09

### Changed

- Change routing logic to redirect `GET` and `HEAD` requests with a trailing slash to the route without one if it exists, and vice versa ([#307](https://github.com/athena-framework/athena/pull/307)) (George Dietrich)

### Added

- Add native tab completion support to the built-in `ATH::Commands` ([#296](https://github.com/athena-framework/athena/pull/296)) (George Dietrich)
- Add support for defining multiple route annotations on a single controller action method ([#315](https://github.com/athena-framework/athena/pull/315)) (George Dietrich)
- Require the new `Athena::Clock` component ([#318](https://github.com/athena-framework/athena/pull/318)) (George Dietrich)
- Add additional `ATH::Spec::APITestCase` request helper methods ([#312](https://github.com/athena-framework/athena/pull/312), [#313](https://github.com/athena-framework/athena/pull/313)) (George Dietrich)

### Fixed

- Fix incorrectly generated route paths with a controller level prefix and no action level `/` prefix ([#308](https://github.com/athena-framework/athena/pull/308)) (George Dietrich)

## [0.18.1] - 2023-05-29

### Added

- Add support for serializing arbitrarily nested controller action return types ([#273](https://github.com/athena-framework/athena/pull/273)) (George Dietrich)
- Allow using constants for controller action's `path` ([#279](https://github.com/athena-framework/athena/pull/279)) (George Dietrich)

### Fixed

- Fix incorrect `content-length` header value when returning multi-byte strings ([#288](https://github.com/athena-framework/athena/pull/288)) (George Dietrich)

## [0.18.0] - 2023-02-20

### Changed

- **Breaking:** upgrade [Athena::EventDispatcher](https://athenaframework.org/EventDispatcher/) to [0.2.x](https://github.com/athena-framework/event-dispatcher/blob/master/CHANGELOG.md#020---2023-01-07) ([#205](https://github.com/athena-framework/athena/pull/205)) (George Dietrich)
- **Breaking:** deprecate the `ATH::ParamConverter` concept in favor of [Value Resolvers](https://athenaframework.org/Framework/Controller/ValueResolvers/Interface) ([#243](https://github.com/athena-framework/athena/pull/243)) (George Dietrich)
- **Breaking:** rename various types/methods to better adhere to https://github.com/crystal-lang/crystal/issues/10374 ([#243](https://github.com/athena-framework/athena/pull/243)) (George Dietrich)
- **Breaking:** Change `ATH::Spec::AbstractBrowser` to be a `class` ([#249](https://github.com/athena-framework/athena/pull/249)) (George Dietrich)
- **Breaking:** upgrade [Athena::Validator](https://athenaframework.org/Validator/) to [0.3.x](https://github.com/athena-framework/validator/blob/master/CHANGELOG.md#030---2023-01-07) ([#250](https://github.com/athena-framework/athena/pull/250)) (George Dietrich)
- Improve service `ATH::Controller`s to not need the `public: true` `ADI::Register` field ([#213](https://github.com/athena-framework/athena/pull/213)) (George Dietrich)
- Update minimum `crystal` version to `~> 1.6.0` ([#205](https://github.com/athena-framework/athena/pull/205)) (George Dietrich)

### Added

- Add trace logging to `ATH::Listeners::CORS` to aid in debugging ([#265](https://github.com/athena-framework/athena/pull/265)) (George Dietrich)
- Introduce new `framework.debug` parameter that is `true` if the binary was _not_ built with the `--release` flag ([#249](https://github.com/athena-framework/athena/pull/249)) (George Dietrich)
- Add built-in [HTTP Expectation](https://athenaframework.org/Framework/Spec/Expectations/HTTP) methods to `ATH::Spec::WebTestCase` ([#249](https://github.com/athena-framework/athena/pull/249)) (George Dietrich)
- Add `#response` and `#request` methods to `ATH::Spec::AbstractBrowser` types ([#249](https://github.com/athena-framework/athena/pull/249)) (George Dietrich)
- Add [ATHR](https://athenaframework.org/Framework/aliases/#ATHR) alias to make using value resolver annotations easier ([#243](https://github.com/athena-framework/athena/pull/243)) (George Dietrich)
- Add [ATH::Commands::Commands::DebugEventDispatcher](https://athenaframework.org/Framework/Commands/DebugEventDispatcher) framework CLI command to aid in debugging the event dispatcher ([#241](https://github.com/athena-framework/athena/pull/241)) (George Dietrich)
- Add [ATH::Commands::Commands::DebugRouter](https://athenaframework.org/Framework/Commands/DebugRouter) and [ATH::Commands::Commands::DebugRouterMatch](https://athenaframework.org/Framework/Commands/DebugRouterMatch) framework CLI commands to aid in debugging the router ([#224](https://github.com/athena-framework/athena/pull/224)) (George Dietrich)
- Add integration for the [Athena::Console](https://athenaframework.org/Console/) component ([#218](https://github.com/athena-framework/athena/pull/218)) (George Dietrich)

### Fixed

- Correctly populate `content-length` based on the response content's size ([#267](https://github.com/athena-framework/athena/pull/267)) (George Dietrich)
- Prevent wildcard CORS `expose_headers` value when `allow_credentials` is `true` ([#264](https://github.com/athena-framework/athena/pull/264)) (George Dietrich)
- Correctly handle `JSON::Serializable` values within `Hash`/`NamedTuple` controller action return types ([#253](https://github.com/athena-framework/athena/pull/253)) (George Dietrich)
- Fix [ATH::ParameterBag#get?](https://athenaframework.org/Framework/ParameterBag/#Athena::Framework::ParameterBag#get?(name,_type)) not returning `nil` if it could not convert the value to the desired type ([#243](https://github.com/athena-framework/athena/pull/243)) (George Dietrich)

## [0.17.1] - 2022-09-05

### Changed

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

- **Breaking:** remove dependency on [amberframework/amber-router](https://github.com/amberframework/amber-router) ([#141](https://github.com/athena-framework/athena/pull/141)) (George Dietrich)

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

[0.19.1]: https://github.com/athena-framework/framework/releases/tag/v0.19.1
[0.19.0]: https://github.com/athena-framework/framework/releases/tag/v0.19.0
[0.18.2]: https://github.com/athena-framework/framework/releases/tag/v0.18.2
[0.18.1]: https://github.com/athena-framework/framework/releases/tag/v0.18.1
[0.18.0]: https://github.com/athena-framework/framework/releases/tag/v0.18.0
[0.17.1]: https://github.com/athena-framework/framework/releases/tag/v0.17.1
[0.17.0]: https://github.com/athena-framework/framework/releases/tag/v0.17.0
[0.16.0]: https://github.com/athena-framework/framework/releases/tag/v0.16.0
[0.15.1]: https://github.com/athena-framework/athena/releases/tag/v0.15.1
[0.15.0]: https://github.com/athena-framework/athena/releases/tag/v0.15.0
