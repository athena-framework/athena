class Article
  include CrSerializer(JSON | YAML)

  # :nodoc:
  def initialize(@id : Int64?, @title : String); end

  property id : Int64?

  property title : String

  # Mock out find method to emulate ORM method
  def self.find(val) : Article?
    if val.to_i == 17
      new 17, "Int"
    elsif val == "71"
      new 71, "String"
    else
      nil
    end
  end
end

class ArticleController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "article/:article_identity_id")]
  @[Athena::Routing::ParamConverter(param: "article_identity", pk_type: Int64, type: Article, converter: Athena::Routing::Converters::Exists)]
  def get_article(article_identity : Article) : Article
    article_identity
  end
end
