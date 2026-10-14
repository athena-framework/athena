require "../spec_helper"

private SECRET = "looooooooooooongenoughtestsecret"

private REQUIRED_CLAIMS = {
  "iss"       => "https://example.com",
  "aud"       => "https://hub.example.com/.well-known/mercure",
  "sub"       => "urn:uuid:1",
  "client_id" => "https://example.com",
}

struct JWTTest < ASPEC::TestCase
  @[DataProvider("create_data")]
  def test_create(
    secret : String,
    algorithm : JWT::Algorithm,
    grants : Array(AMC::Grant),
    additional_claims : Hash?,
    expected_jwt : String,
  ) : Nil
    AMC::TokenFactory::JWT
      .new(secret, algorithm, jwt_lifetime: nil, protocol_version: :legacy)
      .create(grants, additional_claims).should eq expected_jwt
  end

  def create_data : Tuple
    {
      {
        SECRET,
        JWT::Algorithm::HS256,
        [] of AMC::Grant,
        nil,
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJtZXJjdXJlIjp7fX0.Nl9FuNHooqvulVq4efunVwwUBE_VUNr4JC0ivPoZvFM",
      },

      {
        SECRET,
        JWT::Algorithm::HS256,
        [AMC::Grant.new(:publish, ["*"]), AMC::Grant.new(:subscribe, [] of String)],
        nil,
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdLCJzdWJzY3JpYmUiOltdfX0.ZTK3JhEKO1338LAgRMw6j0lkGRMoaZtU4EtGiAylAns", # spellchecker:disable-line
      },

      {
        "looooooooooooooooooooooooooooongenoughtestsecret",
        JWT::Algorithm::HS384,
        [AMC::Grant.new(:publish, ["*"]), AMC::Grant.new(:subscribe, [] of String)],
        nil,
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdLCJzdWJzY3JpYmUiOltdfX0.ERwjuquA1VXjCx_Q05zHHIVWU40maCOLsu493IKD4osTk0l0bTs9t9S8_tgM32Ih",
      },

      {
        "loooooooooooooooooooooooooooooooooooooooooooooongenoughtestsecret",
        JWT::Algorithm::HS512,
        [AMC::Grant.new(:publish, ["*"]), AMC::Grant.new(:subscribe, [] of String)],
        nil,
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdLCJzdWJzY3JpYmUiOltdfX0.eMSnFpi3G0i0lvM_f55E5vUcxkT1GqyVY7qu7c_mZTjKAh4wX3mIJOGoftX7WQRlE1qTVs0OsJ0qyeyet3Yb-g",
      },

      {
        SECRET,
        JWT::Algorithm::HS256,
        [AMC::Grant.new(:publish, ["*"]), AMC::Grant.new(:subscribe, [] of String)],
        {
          "mercure" => {
            "publish"   => ["overridden"],
            "subscribe" => ["overridden"],
            "payload"   => {"foo" => "bar"},
          },
        },
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsib3ZlcnJpZGRlbiJdLCJzdWJzY3JpYmUiOlsib3ZlcnJpZGRlbiJdLCJwYXlsb2FkIjp7ImZvbyI6ImJhciJ9fX0.owz54sSlMuVq2PqtBGFPdrYSXvMKTQc6UQdLEMOlP5s", # spellchecker:disable-line
      },
    }
  end

  def test_legacy_pure_exact_matcher_hash_is_equivalent_to_flat_list : Nil
    factory = AMC::TokenFactory::JWT.new SECRET, jwt_lifetime: nil, protocol_version: :legacy

    factory.create([AMC::Grant.new(:publish, {"exact" => ["*"]})]).should eq factory.create([AMC::Grant.new(:publish, ["*"])])
  end

  def test_legacy_non_exact_matcher_type : Nil
    factory = AMC::TokenFactory::JWT.new SECRET, jwt_lifetime: nil, protocol_version: :legacy

    expect_raises AMC::Exception::InvalidArgument, "Topic matcher type(s) 'urlpattern' require the Mercure protocol 1.0" do
      factory.create [AMC::Grant.new(:publish, {"urlpattern" => ["https://example.com/books/:id"]})]
    end
  end

  def test_legacy_payload : Nil
    factory = AMC::TokenFactory::JWT.new SECRET, jwt_lifetime: nil, protocol_version: :legacy

    expect_raises AMC::Exception::InvalidArgument, "A grant 'payload' is only meaningful under the Mercure protocol 1.0" do
      factory.create [AMC::Grant.new(:subscribe, ["a"], JSON::Any.new("foo"))]
    end
  end

  def test_legacy_lifetime : Nil
    payload = self.decode(AMC::TokenFactory::JWT.new(SECRET, protocol_version: :legacy).create).last

    payload["exp"].as_i64.should be_close (Time.utc + 1.hour).to_unix, 5
  end

  def test_v1_requires_registered_claims : Nil
    expect_raises AMC::Exception::InvalidArgument, "The 'iss' additional claim is required by RFC 9068 access tokens." do
      AMC::TokenFactory::JWT.new(SECRET).create [AMC::Grant.new(:subscribe, ["a"])]
    end
  end

  def test_v1_rejects_empty_registered_claims : Nil
    expect_raises AMC::Exception::InvalidArgument, "The 'aud' additional claim is required by RFC 9068 access tokens." do
      AMC::TokenFactory::JWT.new(SECRET).create [AMC::Grant.new(:subscribe, ["a"])], REQUIRED_CLAIMS.merge({"aud" => ""})
    end

    expect_raises AMC::Exception::InvalidArgument, "The 'aud' additional claim is required by RFC 9068 access tokens." do
      AMC::TokenFactory::JWT.new(SECRET).create [AMC::Grant.new(:subscribe, ["a"])], REQUIRED_CLAIMS.merge({"aud" => [] of String})
    end
  end

  def test_v1_claim_shape : Nil
    header, payload = self.decode AMC::TokenFactory::JWT.new(SECRET).create(
      [
        AMC::Grant.new(:subscribe, {"exact" => ["https://example.com/books/1"], "urlpattern" => ["https://example.com/reviews/:id"]}),
        AMC::Grant.new(:publish, ["*"]),
      ],
      REQUIRED_CLAIMS
    )

    header["alg"].should eq "HS256"
    header["typ"].should eq "at+jwt"

    payload["mercure"]?.should be_nil
    payload["iss"].should eq "https://example.com"
    payload["aud"].should eq "https://hub.example.com/.well-known/mercure"
    payload["sub"].should eq "urn:uuid:1"
    payload["client_id"].should eq "https://example.com"

    payload["authorization_details"].should eq JSON.parse <<-JSON
      [
        {
          "type": "https://mercure.rocks/authorization-detail",
          "actions": ["subscribe"],
          "topics": [
            {"match": "https://example.com/books/1"},
            {"match": "https://example.com/reviews/:id", "match_type": "urlpattern"}
          ]
        },
        {
          "type": "https://mercure.rocks/authorization-detail",
          "actions": ["publish"],
          "topics": [{"match": "*"}]
        }
      ]
      JSON

    payload["iat"].as_i64.should be_close Time.utc.to_unix, 5
    payload["exp"].as_i64.should be_close (Time.utc + 1.hour).to_unix, 5
    payload["jti"].as_s.size.should eq 32
  end

  def test_v1_unique_token_ids : Nil
    factory = AMC::TokenFactory::JWT.new SECRET

    self.decode(factory.create(additional_claims: REQUIRED_CLAIMS)).last["jti"].should_not eq self.decode(factory.create(additional_claims: REQUIRED_CLAIMS)).last["jti"]
  end

  def test_v1_provided_claims_take_precedence : Nil
    payload = self.decode(AMC::TokenFactory::JWT.new(SECRET).create(
      additional_claims: REQUIRED_CLAIMS.merge({"iat" => "1", "jti" => "ID", "exp" => "2"})
    )).last

    payload["iat"].should eq "1"
    payload["jti"].should eq "ID"
    payload["exp"].should eq "2"
  end

  def test_v1_without_lifetime : Nil
    self.decode(AMC::TokenFactory::JWT.new(SECRET, jwt_lifetime: nil).create(additional_claims: REQUIRED_CLAIMS)).last["exp"]?.should be_nil
  end

  def test_v1_single_grant_with_both_actions_produces_one_entry : Nil
    payload = self.decode(AMC::TokenFactory::JWT.new(SECRET).create(
      [AMC::Grant.new(AMC::Grant::Action.flags(Subscribe, Publish), ["a"])],
      REQUIRED_CLAIMS
    )).last

    payload["authorization_details"].size.should eq 1
    payload["authorization_details"][0]["actions"].should eq JSON.parse %(["subscribe", "publish"])
    payload["authorization_details"][0]["topics"].should eq JSON.parse %([{"match": "a"}])
  end

  def test_v1_payload_is_attached_to_subscribe_detail : Nil
    payload = self.decode(AMC::TokenFactory::JWT.new(SECRET).create(
      [AMC::Grant.new(:subscribe, ["a"], JSON.parse(%({"foo": "bar"})))],
      REQUIRED_CLAIMS
    )).last

    payload["authorization_details"][0]["payload"].should eq JSON.parse %({"foo": "bar"})
  end

  def test_v1_grants_without_topics_are_skipped : Nil
    payload = self.decode(AMC::TokenFactory::JWT.new(SECRET).create(
      [AMC::Grant.new(:subscribe, [] of String), AMC::Grant.new(:publish, {"urlpattern" => [] of String})],
      REQUIRED_CLAIMS.merge({"authorization_details" => "provided"})
    )).last

    payload["authorization_details"].should eq "provided"
  end

  def test_v1_grants_replace_provided_authorization_details : Nil
    payload = self.decode(AMC::TokenFactory::JWT.new(SECRET).create(
      [AMC::Grant.new(:subscribe, ["a"])],
      REQUIRED_CLAIMS.merge({"authorization_details" => "provided"})
    )).last

    payload["authorization_details"][0]["topics"].should eq JSON.parse %([{"match": "a"}])
  end

  def test_v1_grant_without_actions : Nil
    expect_raises AMC::Exception::InvalidArgument, "A grant must declare at least one action." do
      AMC::TokenFactory::JWT.new(SECRET).create [AMC::Grant.new(:none, ["a"])], REQUIRED_CLAIMS
    end
  end

  def test_v1_payload_without_topics : Nil
    expect_raises AMC::Exception::InvalidArgument, "A grant 'payload' requires at least one topic." do
      AMC::TokenFactory::JWT.new(SECRET).create [AMC::Grant.new(:subscribe, [] of String, JSON::Any.new("foo"))], REQUIRED_CLAIMS
    end
  end

  def test_v1_payload_on_publish_only_grant : Nil
    expect_raises AMC::Exception::InvalidArgument, "A grant 'payload' is only meaningful when its actions include 'subscribe'" do
      AMC::TokenFactory::JWT.new(SECRET).create [AMC::Grant.new(:publish, ["a"], JSON::Any.new("foo"))], REQUIRED_CLAIMS
    end
  end

  private def decode(token : String) : Tuple(JSON::Any, JSON::Any)
    header, payload, _ = token.split '.'

    {JSON.parse(Base64.decode_string(header)), JSON.parse(Base64.decode_string(payload))}
  end
end
