struct Athena::Mercure::TokenFactory::JWT
  include Athena::Mercure::TokenFactory::Interface

  # These make it easier to build the JSON in a type safe way vs dealing with merging hashes and such :shrug:
  private record MercurePayload, subscribe : Array(String)?, publish : Array(String)? do
    def to_json(builder : JSON::Builder) : Nil
      builder.object do
        if publish = @publish
          builder.field "publish", publish
        end

        if subscribe = @subscribe
          builder.field "subscribe", subscribe
        end
      end
    end
  end

  private record Payload(T), mercure : MercurePayload, jwt_lifetime : Time::Span?, additional_claims : T do
    def to_json(builder : JSON::Builder) : Nil
      builder.object do
        builder.field "mercure", @mercure

        if (lifetime = @jwt_lifetime) && !@additional_claims.try &.has_key? "exp"
          builder.field "exp", (Time.utc + lifetime).to_unix
        end

        additional_claims.try &.each do |k, v|
          builder.field k, v
        end
      end
    end
  end

  @jwt_lifetime : Time::Span?

  def initialize(
    @jwt_secret : String,
    @algorithm : ::JWT::Algorithm = :hs256,
    jwt_lifetime : Int32 | Time::Span | Nil = 3600,
    @passphrase : String = "",
  )
    @jwt_lifetime = jwt_lifetime.is_a?(Int32) ? jwt_lifetime.seconds : jwt_lifetime
  end

  def create(
    subscribe : Array(String)? = [] of String,
    publish : Array(String)? = [] of String,
    additional_claims : Hash? = nil,
  ) : String
    ::JWT.encode(
      Payload.new(MercurePayload.new(subscribe, publish), @jwt_lifetime, additional_claims),
      @jwt_secret,
      @algorithm
    )
  end
end
