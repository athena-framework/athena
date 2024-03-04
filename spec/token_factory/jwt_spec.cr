require "../spec_helper"

struct JWTTest < ASPEC::TestCase
  @[DataProvider("create_data")]
  def test_create(
    secret : String,
    algorithm : JWT::Algorithm,
    subscribe : Array(String)?,
    publish : Array(String)?,
    additional_claims : Hash?,
    expected_jwt : String
  ) : Nil
    AMC::TokenFactory::JWT
      .new(secret, algorithm, jwt_lifetime: nil)
      .create(subscribe, publish, additional_claims).should eq expected_jwt
  end

  def create_data : Tuple
    {
      {
        "looooooooooooongenoughtestsecret",
        JWT::Algorithm::HS256,
        nil,
        nil,
        nil,
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJtZXJjdXJlIjp7fX0.Nl9FuNHooqvulVq4efunVwwUBE_VUNr4JC0ivPoZvFM",
      },

      {
        "looooooooooooongenoughtestsecret",
        JWT::Algorithm::HS256,
        Array(String).new,
        ["*"],
        nil,
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdLCJzdWJzY3JpYmUiOltdfX0.ZTK3JhEKO1338LAgRMw6j0lkGRMoaZtU4EtGiAylAns",
      },

      {
        "looooooooooooooooooooooooooooongenoughtestsecret",
        JWT::Algorithm::HS384,
        Array(String).new,
        ["*"],
        nil,
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdLCJzdWJzY3JpYmUiOltdfX0.ERwjuquA1VXjCx_Q05zHHIVWU40maCOLsu493IKD4osTk0l0bTs9t9S8_tgM32Ih",
      },

      {
        "looooooooooooongenoughtestsecret",
        JWT::Algorithm::HS256,
        Array(String).new,
        ["*"],
        {
          "mercure" => {
            "publish"   => ["overridden"],
            "subscribe" => ["overridden"],
            "payload"   => {"foo" => "bar"},
          },
        },
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJtZXJjdXJlIjp7InB1Ymxpc2giOlsiKiJdLCJzdWJzY3JpYmUiOltdfSwibWVyY3VyZSI6eyJwdWJsaXNoIjpbIm92ZXJyaWRkZW4iXSwic3Vic2NyaWJlIjpbIm92ZXJyaWRkZW4iXSwicGF5bG9hZCI6eyJmb28iOiJiYXIifX19.X9IUAOq-12pRpO5oNnwnQsdZPAQQfan83DpJI32IxlI",
      },
    }
  end
end
