require "athena-serializer"

require "./serializer/component_serializer"

@[ADI::Register]
@[ADI::AsAlias]
struct Athena::Serializer::Serializer; end

@[ADI::Register]
struct Athena::Serializer::Navigators::NavigatorFactory; end

@[ADI::Register]
struct Athena::Serializer::InstantiateObjectConstructor; end
