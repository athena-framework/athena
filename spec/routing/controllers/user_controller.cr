require "xml"

class Customer
  include CrSerializer(JSON | YAML)

  # :nodoc:
  def initialize; end

  property name : String = "MyCust"
  property id : Int32 = 1
end

class User
  include CrSerializer(JSON | YAML)

  # :nodoc:
  def initialize(@id : Int64?, @age : Int32); end

  property id : Int64?

  @[Assert::GreaterThan(value: 0)]
  property age : Int32

  @[CrSerializer::Options(groups: ["admin"])]
  property password : String = "monkey"

  @[CrSerializer::Expandable]
  property customer : Customer?

  def customer : Customer
    Customer.new
  end

  # Mock out find method to emulate ORM method
  def self.find(val) : User?
    if val.to_i == 17
      new 17, 123
    elsif val == "71"
      new 71, 321
    else
      nil
    end
  end

  def to_xml : String
    XML.build do |xml|
      xml.element("user", id: 17) do
        xml.element("age") { xml.text @age.to_s }
      end
    end
  end

  def self.from_form_data(form_data : HTTP::Params) : self
    new form_data["id"].to_i64?, form_data["age"].to_i
  end

  ECR.def_to_s "spec/routing/user.ecr"
end

struct CustomRenderer < Athena::Routing::Renderers::Renderer
  def render(response : T, groups : Array(String) = [] of String) : String forall T
    @request_stack.response.headers.add "Content-Type", "X-CUSTOM-TYPE"
    # Since not all types implement a `to_xml` method, I have to tell compiler its a `User` type.
    response.as(User).to_xml
  end
end

class UserController < Athena::Routing::Controller
  @[Athena::Routing::Post(path: "users")]
  @[Athena::Routing::ParamConverter(param: "body", type: User, converter: Athena::Routing::Converters::RequestBody)]
  def new_user(body : User) : User
    body.id = 12
    body
  end

  @[Athena::Routing::Post(path: "users/form")]
  @[Athena::Routing::ParamConverter(param: "body", type: User, converter: Athena::Routing::Converters::FormData)]
  def new_form_user(body : User) : User
    body.should be_a User
    body.id.should eq 99
    body.age.should eq 1
    body.password.should eq "monkey"
    body
  end

  @[Athena::Routing::Put(path: "users")]
  @[Athena::Routing::ParamConverter(param: "body", type: User, converter: Athena::Routing::Converters::RequestBody)]
  def update_user(body : User) : User
    body.should be_a User
    body.id.should eq 17_i64
    body.age.should eq 99
    body.password.should eq "monkey"
    body
  end

  @[Athena::Routing::Get(path: "users/yaml/:user_id")]
  @[Athena::Routing::ParamConverter(param: "user_id", pk_type: Int64, type: User, converter: Athena::Routing::Converters::Exists)]
  @[Athena::Routing::View(renderer: Athena::Routing::Renderers::YAMLRenderer)]
  def get_user_yaml(user_id : User) : User
    user_id
  end

  @[Athena::Routing::Get(path: "users/ecr/:user_id")]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int64, type: User, converter: Athena::Routing::Converters::Exists)]
  @[Athena::Routing::View(renderer: Athena::Routing::Renderers::ECRRenderer)]
  def get_user_ecr(user : User) : User
    user
  end

  @[Athena::Routing::Get(path: "users/custom/:user_id")]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int64, type: User, converter: Athena::Routing::Converters::Exists)]
  @[Athena::Routing::View(renderer: CustomRenderer)]
  def get_user_custom(user : User) : User
    user
  end

  @[Athena::Routing::Get(path: "users/:user_id")]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int64, type: User, converter: Athena::Routing::Converters::Exists)]
  def get_user(user : User) : User
    user.should be_a User
    user.id.should eq 17
    user.age.should eq 123
    user.password.should eq "monkey"
    user
  end

  @[Athena::Routing::Get(path: "users/str/:user_id")]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: String, type: User, converter: Athena::Routing::Converters::Exists)]
  def get_user_string(user : User) : User
    user.should be_a User
    user.id.should eq 71
    user.age.should eq 321
    user.password.should eq "monkey"
    user
  end

  @[Athena::Routing::Get(path: "admin/users/:user_id")]
  @[Athena::Routing::View(groups: ["admin"])]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int64, type: User, converter: Athena::Routing::Converters::Exists)]
  def get_user_admin(user : User) : User
    user.should be_a User
    user.id.should eq 17
    user.age.should eq 123
    user.password.should eq "monkey"
    user
  end

  @[Athena::Routing::Get(path: "admin/users/:user_id/all")]
  @[Athena::Routing::View(groups: ["admin", "default"])]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int64, type: User, converter: Athena::Routing::Converters::Exists)]
  def get_user_admin_all(user : User) : User
    user.should be_a User
    user.id.should eq 17
    user.age.should eq 123
    user.password.should eq "monkey"
    user
  end

  @[Athena::Routing::Get(path: "users/:user_id/articles/:article_id")]
  @[Athena::Routing::ParamConverter(param: "article", pk_type: Int64, type: Article, converter: Athena::Routing::Converters::Exists)]
  @[Athena::Routing::ParamConverter(param: "user", pk_type: Int64, type: User, converter: Athena::Routing::Converters::Exists)]
  def double_converter_exists(user : User, article : Article) : String
    "#{user.age} #{article.title}"
  end

  @[Athena::Routing::Post(path: "users/articles/:article_id")]
  @[Athena::Routing::ParamConverter(param: "article", pk_type: Int64, type: Article, converter: Athena::Routing::Converters::Exists)]
  @[Athena::Routing::ParamConverter(param: "body", type: User, converter: Athena::Routing::Converters::RequestBody)]
  def double_converter_exists_and_body(body : User, article : Article) : String
    "#{body.age} #{article.title}"
  end
end
