# Creates an `AHTTP::Session::Storage` with the provided configuration for the session of each request.
class Athena::HTTP::Session::Storage::Factory
  include Athena::HTTP::Session::Storage::FactoryInterface

  @clock : AHTTP::Session::Storage::MetadataBag::Clock?

  # See `AHTTP::Session::Storage#initialize` and `AHTTP::Session::Storage::MetadataBag#initialize` for what each argument does.
  def initialize(
    @handler : AHTTP::Session::Storage::Handler::Interface,
    @name : String = "athena_session_id",
    @gc_max_lifetime : Int32 = 1440,
    @gc_probability : Int32 = 1,
    @gc_divisor : Int32 = 100,
    @cookie_lifetime : Int32 = 0,
    @metadata_update_threshold : Int32 = 0,
    @clock : AHTTP::Session::Storage::MetadataBag::Clock? = nil,
  )
  end

  # :inherit:
  def create_storage(request : AHTTP::Request?) : AHTTP::Session::Storage::Interface
    AHTTP::Session::Storage.new(
      @handler,
      AHTTP::Session::Storage::MetadataBag.new(update_threshold: @metadata_update_threshold, cookie_lifetime: @cookie_lifetime, clock: @clock),
      name: @name,
      gc_max_lifetime: @gc_max_lifetime,
      gc_probability: @gc_probability,
      gc_divisor: @gc_divisor,
    )
  end
end
