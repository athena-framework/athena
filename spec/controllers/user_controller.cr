class User
  include CrSerializer

  @[Assert::GreaterThan(value: 0)]
  property age : Int32 = 12

  def self.find(val)
    val == 1 ? self.new : nil
  end
end

class UserController < Athena::ClassController
  @[Athena::Post(path: "users")]
  @[Athena::ParamConverter(param: "user", type: User, converter: RequestBody)]
  def self.newUser(user : User) : User
    user
  end
end
