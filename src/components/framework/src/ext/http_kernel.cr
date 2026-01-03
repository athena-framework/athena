@[ADI::Register(name: "athena_http_kernel", public: true)]
struct Athena::HTTPKernel::HTTPKernel; end

@[ADI::Register]
struct Athena::HTTPKernel::Listeners::Routing; end

@[ADI::Register]
struct Athena::HTTPKernel::Listeners::Error; end

@[ADI::Register]
@[ADI::AsAlias]
class Athena::HTTPKernel::ActionResolver; end

ADI.bind value_resolvers : Array(Athena::HTTPKernel::Controller::ValueResolvers::Interface), "!athena.controller.value_resolver"

@[ADI::Register(name: "parameter_resolver_request_attribute", tags: [{name: ATHR::Interface::TAG, priority: 100}])]
struct Athena::HTTPKernel::Controller::ValueResolvers::RequestAttribute; end

@[ADI::Register(name: "parameter_resolver_request", tags: [{name: ATHR::Interface::TAG, priority: 50}])]
struct Athena::HTTPKernel::Controller::ValueResolvers::Request; end

@[ADI::Register(tags: [{name: ATHR::Interface::TAG, priority: -100}])]
struct Athena::HTTPKernel::Controller::ValueResolvers::DefaultValue; end

@[ADI::Register]
@[ADI::AsAlias]
struct Athena::HTTPKernel::Controller::ArgumentResolver; end

@[ADI::Register(_debug: "%framework.debug%")]
@[ADI::AsAlias(AHK::ErrorRendererInterface)]
struct Athena::HTTPKernel::ErrorRenderer; end
