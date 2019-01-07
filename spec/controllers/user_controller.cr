class User
  include YAML::Serializable
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

  def self.from_form_data(form_data : HTTP::Params) : self
    obj = new
    obj.age = form_data["age"].to_i
    obj.id = form_data["id"].to_i64
    obj
  end

  ECR.def_to_s "spec/user.ecr"
end

class UserController < Athena::ClassController
  @[Athena::Post(path: "users")]
  @[Athena::ParamConverter(param: "user", type: User, converter: RequestBody)]
  def self.new_user(user : User) : User
    user.id = 12
    user
  end

  @[Athena::Post(path: "users/form")]
  @[Athena::ParamConverter(param: "user", type: User, converter: FormData)]
  def self.new_form_user(user : User) : User
    it "should run correctly" do
      user.should be_a User
      user.id.should eq 99
      user.age.should eq 1
      user.password.should eq "monkey"
    end
    user
  end

  @[Athena::Put(path: "users")]
  @[Athena::ParamConverter(param: "user", type: User, converter: RequestBody)]
  def self.update_user(user : User) : User
    it "should run correctly" do
      user.should be_a User
      user.id.should eq 17_i64
      user.age.should eq 99
      user.password.should eq "monkey"
    end
    user
  end

  @[Athena::Get(path: "users/yaml/:id")]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  @[Athena::View(renderer: YAMLRenderer)]
  def self.get_user_yaml(user : User) : User
    user
  end

  @[Athena::Get(path: "users/ecr/:id")]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  @[Athena::View(renderer: ECRRenderer)]
  def self.get_user_ecr(user : User) : User
    user
  end

  @[Athena::Get(path: "users/:id")]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  def self.get_user(user : User) : User
    it "should run correctly" do
      user.should be_a User
      user.id.should eq 17
      user.age.should eq 123
      user.password.should eq "monkey"
    end
    user
  end

  @[Athena::Get(path: "admin/users/:id")]
  @[Athena::View(groups: ["admin"])]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  def self.get_user_admin(user : User) : User
    it "should run correctly" do
      user.should be_a User
      user.id.should eq 17
      user.age.should eq 123
      user.password.should eq "monkey"
    end
    user
  end

  @[Athena::Get(path: "admin/users/:id/all")]
  @[Athena::View(groups: ["admin", "default"])]
  @[Athena::ParamConverter(param: "user", type: User, converter: Exists)]
  def self.get_user_admin_all(user : User) : User
    it "should run correctly" do
      user.should be_a User
      user.id.should eq 17
      user.age.should eq 123
      user.password.should eq "monkey"
    end
    user
  end
end
