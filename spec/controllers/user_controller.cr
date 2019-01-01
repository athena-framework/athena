class User
  include CrSerializer

  property id : Int64?

  @[Assert::GreaterThan(value: 0)]
  property age : Int32

  @[CrSerializer::Options(groups: ["admin"])]
  property password : String = "monkey"

  # Mock out find method to emulate ORM method
  def self.find(val) : User?
    if val == 17
      user : self = new
      user.id = 17
      user.age = 123
      return user
    else
      return nil
    end
  end
end

class UserController < Athena::ClassController
  @[Athena::Post(path: "users")]
  @[Athena::ParamConverter(param: "user", type: User, converter: RequestBody)]
  def self.newUser(user : User) : User
    user.id = 12
    user
  end

  @[Athena::Put(path: "users")]
  @[Athena::ParamConverter(param: "user", type: User, converter: RequestBody)]
  def self.updateUser(user : User) : User
    user
  end

  @[Athena::Get(path: "users/:id")]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  def self.getUser(user : User) : User
    it "should run correctly" do
      user.should be_a User
      user.id.should eq 17
      user.age.should eq 123
      user.age.should eq "monkey"
    end
    user
  end

  @[Athena::Get(path: "admin/users/:id")]
  @[Athena::View(groups: ["admin"])]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  def self.getUserAdmin(user : User) : User
    it "should run correctly" do
      user.should be_a User
      user.id.should eq 17
      user.age.should eq 123
      user.age.should eq "monkey"
    end
    user
  end

  @[Athena::Get(path: "admin/users/:id/all")]
  @[Athena::View(groups: ["admin", "default"])]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  def self.getUserAdminAll(user : User) : User
    it "should run correctly" do
      user.should be_a User
      user.id.should eq 17
      user.age.should eq 123
      user.age.should eq "monkey"
    end
    user
  end
end
