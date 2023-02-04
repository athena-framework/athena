# Changelog

## [0.2.1] - 2023-02-04

### Added

- Add better integration between `Athena::EventDispatcher` and `Athena::DependencyInjection` ([#259](https://github.com/athena-framework/athena/pull/259)) (George Dietrich)

## [0.2.0] - 2023-01-07

### Changed

- **Breaking:** refactor how listeners are registered to use the new `AEDA::AsEventListener` annotation on the method instead of the `self.subscribed_events` class method ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- **Breaking:** refactor and rename the majority of `AED::EventDispatcherInterface` API ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- **Breaking:** change the representation of a listener when returned from a dispatcher to be an `AED::Callable` instance ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- **Breaking:** refactor `AED::Event` to now be `abstract` ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)

### Added

- Add `AED::GenericEvent` that can be used for convenience within simple use cases ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- Add the ability to use a listener method without the `AED::EventDispatcherInterface` parameter ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)

### Removed

- **Breaking:** remove ability for listeners to automatically be registered with the dispatcher ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- **Breaking:** remove the `AED::EventDispatcher.new` constructor that accepts an `Array(AED::EventListenerInterface)` ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- **Breaking:** remove the `AED::EventListenerType` alias ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- **Breaking:** remove the `AED::SubscribedEvents` alias ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- **Breaking:** remove the `AED::EventListener` struct ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- **Breaking:** remove the `AED.create_listener` method ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)
- Remove the requirement that listeners methods need to be called `call` ([#236](https://github.com/athena-framework/athena/pull/236)) (George Dietrich)

## [0.1.4] - 2022-05-14

_First release a part of the monorepo._

### Added

- Add getting started documentation to API docs ([#172](https://github.com/athena-framework/athena/pull/172)) (George Dietrich)

### Changed

- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)

### Fixed

- Fix the `VERSION` constant's value ([#166](https://github.com/athena-framework/athena/pull/166)) (George Dietrich)

## [0.1.3] - 2021-01-29

### Changed

- Migrate documentation to [MkDocs](https://mkdocstrings.github.io/crystal/) ([#14](https://github.com/athena-framework/event-dispatcher/pull/14)) (George Dietrich)

## [0.1.2] - 2020-12-03

### Changed

- Update `crystal` version to allow version greater than `1.0.0` ([#13](https://github.com/athena-framework/event-dispatcher/pull/13)) (George Dietrich)

## [0.1.1] - 2020-11-12

### Added

- Add the [AED::Spec](https://athenaframework.org/EventDispatcher/Spec/) module to provide helpful testing utilities ([#11](https://github.com/athena-framework/event-dispatcher/pull/11)) (George Dietrich)

## [0.1.0] - 2020-01-11

_Initial release._

[0.2.1]: https://github.com/athena-framework/event-dispatcher/releases/tag/v0.2.1
[0.2.0]: https://github.com/athena-framework/event-dispatcher/releases/tag/v0.2.0
[0.1.4]: https://github.com/athena-framework/event-dispatcher/releases/tag/v0.1.4
[0.1.3]: https://github.com/athena-framework/event-dispatcher/releases/tag/v0.1.3
[0.1.2]: https://github.com/athena-framework/event-dispatcher/releases/tag/v0.1.2
[0.1.1]: https://github.com/athena-framework/event-dispatcher/releases/tag/v0.1.1
[0.1.0]: https://github.com/athena-framework/event-dispatcher/releases/tag/v0.1.0
