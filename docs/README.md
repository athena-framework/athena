## Athena

Athena is a collection of general-purpose, robust, independent, and reusable components with the goal of powering a software ecosystem.
These include:

* [Clock](/Clock/) (`ACLK`) - Decouples applications from the system clock
* [Console](/Console/) (`ACON`) - Allows the creation of CLI based commands
* [Contracts](/Contracts/) (`ACTR`) - A set of abstractions extracted out of the Athena components
* [DependencyInjection](/DependencyInjection/) (`ADI`) - Robust dependency injection service container framework
* [Dotenv](/Dotenv/) - Registers environment variables from a `.env` file
* [EventDispatcher](/EventDispatcher/) (`AED`) - A Mediator and Observer pattern event library
* [Framework](/Framework/) (`ATH`) - Integrates the components into a single cohesive, flexible, and modular framework
* [HTTP](/HTTP/) (`AHTTP`) - Shared common HTTP abstractions/utilities
* [ImageSize](/ImageSize/) (`AIS`) - Measures the size of various image formats
* [Mercure](/Mercure/) (`AMC`) - Allows easily pushing updates to web browsers and other HTTP clients using the Mercure protocol
* [MIME](/MIME/) (`AMIME`) - Allows manipulating `MIME` messages
* [Negotiation](/Negotiation/) (`ANG`) - Framework agnostic content negotiation library
* [Routing](/Routing/) (`ART`) - A performant and robust HTTP based routing library/framework
* [Serializer](/Serializer/) (`ASR`) - Object (de)serialization library
* [Spec](/Spec/) (`ASPEC`) - Common/helpful [Spec](https://crystal-lang.org/api/Spec.html) compliant testing utilities
* [Validator](/Validator/) (`AVD`) - Object/value validation library

These components may be used on their own to aid in existing projects or integrated into existing (or new) frameworks.

TIP: Each component may also define additional shortcut aliases. Check the `Aliases` page of each component in the [API Reference](./api_reference.md) for more information.

## Athena Framework

Athena also provides the [Framework](./getting_started/README.md) component that integrates select components into a single cohesive, flexible, and modular framework.
It is designed in such a way to be non-intrusive and not require a strict organizational convention in regards to how a project is setup;
this allows it to use a minimal amount of setup boilerplate while not preventing it for more complex projects.
Not every component needs to be used or understood to start using the framework, only those which are required for the task at hand.

### Feature Highlights

Athena Framework has quite a few unique features that set it a part from other Crystal frameworks:

* Follows the SOLID principles to encourage good software design
* Architected in such a way to allow maximum flexibility without needing to fight against the framework
* Uses annotations as a means of extension/customization
* Built-in testing utilities

TIP: The [demo](https://github.com/athena-framework/demo) application serves as a good example of what an application using the framework could look like.

## Resources

* [Discord Server](https://discord.gg/TmDVPb3dmr)
* [GitHub Repository](https://github.com/athena-framework/athena)
