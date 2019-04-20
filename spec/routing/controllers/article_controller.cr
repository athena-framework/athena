class Article
  include CrSerializer(JSON | YAML)

  property id : Int64?

  property title : String

  # Mock out find method to emulate ORM method
  def self.find(val) : Article?
    user : self = new
    if val.to_i == 17
      user.id = 17
      user.title = "Int"
      user
    elsif val == "71"
      user.id = 71
      user.title = "String"
      user
    else
      nil
    end
  end
end

class ArticleController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "article/:article_identity_id")]
  @[Athena::Routing::ParamConverter(param: "article_identity", pk_type: Int64, type: Article, converter: Exists)]
  def get_article(article_identity : Article) : Article
    article_identity
  end
end
