# A token factory implementation based on the [Crystal JWT](https://github.com/crystal-community/jwt) shard.
#
# Under the Mercure protocol 1.0, it creates [RFC 9068](https://datatracker.ietf.org/doc/html/rfc9068) access tokens.
# The grants are encoded as its `authorization_details` claim, and the `iss`, `aud`, `sub`, and `client_id` claims must be provided as *additional_claims*, such as via `AMC::TokenFactory::DefaultClaims`.
# Under the Mercure protocol 0.x, the grants are encoded as its `mercure` claim, which only supports topics that are matched exactly, and no payload.
#
# NOTE: Only available if the `jwt` shard is installed and required, see the [installation](/Mercure/#installation) instructions.
struct Athena::Mercure::TokenFactory::JWT
  include Athena::Mercure::TokenFactory::Interface

  private AUTHORIZATION_DETAIL_TYPE = "https://mercure.rocks/authorization-detail"
  private REQUIRED_CLAIMS           = {"iss", "aud", "sub", "client_id"}

  # These make it easier to build the JSON in a type safe way vs dealing with merging hashes and such :shrug:
  private record LegacyPayload(T), topics_by_action : Hash(String, Array(String)), jwt_lifetime : Time::Span?, additional_claims : T do
    def to_json(builder : JSON::Builder) : Nil
      builder.object do
        builder.field "mercure" do
          builder.object do
            # An additional `mercure` claim is merged into the one built from the grants.
            mercure_claim = @additional_claims.try &.["mercure"]?
            mercure_claim = nil unless mercure_claim.is_a? Hash

            @topics_by_action.each do |action, topics|
              if mercure_claim && mercure_claim.has_key? action
                builder.field action, mercure_claim[action]
              else
                builder.field action, topics
              end
            end

            mercure_claim.try &.each do |k, v|
              builder.field k.to_s, v unless @topics_by_action.has_key? k
            end
          end
        end

        if (lifetime = @jwt_lifetime) && !@additional_claims.try &.has_key? "exp"
          builder.field "exp", (Time.utc + lifetime).to_unix
        end

        @additional_claims.try &.each do |k, v|
          builder.field k.to_s, v unless "mercure" == k
        end
      end
    end
  end

  private record V1Payload(T), grants : Array(AMC::Grant), jwt_lifetime : Time::Span?, additional_claims : T do
    def to_json(builder : JSON::Builder) : Nil
      grants = @grants.select &.topics?

      builder.object do
        @additional_claims.try &.each do |k, v|
          # The grants replace a provided `authorization_details` claim.
          next if "authorization_details" == k && !grants.empty?

          builder.field k.to_s, v
        end

        unless grants.empty?
          builder.field "authorization_details" do
            builder.array do
              grants.each { |grant| self.authorization_detail builder, grant }
            end
          end
        end

        unless @additional_claims.try &.has_key? "iat"
          builder.field "iat", Time.utc.to_unix
        end

        unless @additional_claims.try &.has_key? "jti"
          builder.field "jti", Random::Secure.hex 16
        end

        if (lifetime = @jwt_lifetime) && !@additional_claims.try &.has_key? "exp"
          builder.field "exp", (Time.utc + lifetime).to_unix
        end
      end
    end

    private def authorization_detail(builder : JSON::Builder, grant : AMC::Grant) : Nil
      builder.object do
        builder.field "type", AUTHORIZATION_DETAIL_TYPE

        builder.field "actions" do
          builder.array do
            grant.actions.each { |action, _| builder.string action.to_s.downcase }
          end
        end

        builder.field "topics" do
          builder.array do
            grant.topics_by_matcher.each do |matcher_type, patterns|
              patterns.each do |pattern|
                builder.object do
                  builder.field "match", pattern
                  builder.field "match_type", matcher_type unless "exact" == matcher_type
                end
              end
            end
          end
        end

        if payload = grant.payload
          builder.field "payload", payload
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
    @protocol_version : AMC::ProtocolVersion = :v1,
  )
    @jwt_lifetime = jwt_lifetime.is_a?(Int32) ? jwt_lifetime.seconds : jwt_lifetime
  end

  # :inherit:
  def create(
    grants : Array(AMC::Grant) = [] of AMC::Grant,
    additional_claims : Hash? = nil,
  ) : String
    if @protocol_version.v1?
      self.validate_v1 grants, additional_claims

      ::JWT.encode V1Payload.new(grants, @jwt_lifetime, additional_claims), @jwt_secret, @algorithm, typ: "at+jwt"
    else
      ::JWT.encode LegacyPayload.new(self.topics_by_action(grants), @jwt_lifetime, additional_claims), @jwt_secret, @algorithm
    end
  end

  private def validate_v1(grants : Array(AMC::Grant), additional_claims : Hash?) : Nil
    grants.each do |grant|
      raise AMC::Exception::InvalidArgument.new "A grant must declare at least one action." if grant.actions.none?

      unless grant.topics?
        raise AMC::Exception::InvalidArgument.new "A grant 'payload' requires at least one topic." if grant.payload

        next
      end

      if grant.payload && !grant.actions.subscribe?
        raise AMC::Exception::InvalidArgument.new "A grant 'payload' is only meaningful when its actions include 'subscribe', as the hub never surfaces one on a publish-only grant."
      end
    end

    REQUIRED_CLAIMS.each do |claim|
      value = additional_claims.try &.[claim]?

      if value.nil? || (value.responds_to?(:empty?) && value.empty?)
        raise AMC::Exception::InvalidArgument.new "The '#{claim}' additional claim is required by RFC 9068 access tokens."
      end
    end
  end

  private def topics_by_action(grants : Array(AMC::Grant)) : Hash(String, Array(String))
    grants.each_with_object({} of String => Array(String)) do |grant, topics_by_action|
      if grant.payload
        raise AMC::Exception::InvalidArgument.new "A grant 'payload' is only meaningful under the Mercure protocol 1.0, but this factory is configured for the 0.x protocol."
      end

      topics_by_matcher = grant.topics_by_matcher

      unless (unsupported = topics_by_matcher.keys - ["exact"]).empty?
        raise AMC::Exception::InvalidArgument.new "Topic matcher type(s) '#{unsupported.join("', '")}' require the Mercure protocol 1.0, but this factory is configured for the 0.x protocol and only supports 'exact' topic matching."
      end

      topics = topics_by_matcher["exact"]? || [] of String

      grant.actions.each do |action, _|
        (topics_by_action[action.to_s.downcase] ||= [] of String).concat topics
      end
    end
  end
end
