require "athena-serializer"

@[ADI::Register]
struct Athena::Serializer::Serializer; end

struct Athena::Routing::Listeners::View
  def initialize(@serializer : ASR::SerializerInterface); end

  protected def serialize(data, io : IO)
    @serializer.serialize data, :json, io
  end
end

@[ADI::Register]
struct Athena::Serializer::Navigators::NavigatorFactory; end

@[ADI::Register]
struct Athena::Serializer::InstantiateObjectConstructor; end
