# :nodoc:
#
# Closes each `ATH::Closeable` service once a request is done.
@[ADI::Register(public: true, _closeables: "!athena.closeable")]
struct Athena::Framework::ServicesCloser
  def initialize(@closeables : Array(ATH::Closeable)); end

  def close : Nil
    @closeables.each &.close
  end
end
