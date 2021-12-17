The [Serializer][Athena::Serializer] component adds enhanced (de)serialization features. This component is mostly optional, but is integrated into the default view layer of Athena.

When an [ASR::Serializable][Athena::Serializer::Serializable] is returned from a controller action, that object will be serialized via the serializer component, as opposed to Crystal's standard libraries' `#to_json` method.

INFO: If an object implements _both_ `ASR::Serializable` and `JSON::Serializable`, the serializer component takes priority.

The [ATHA::View][Athena::Framework::Annotations::View] annotation can be used to configure serialization related options on a per route basis.

```crystal
require "athena"

class Article
  include ASR::Serializable
  
  # Assume this is defined via an ORM
  def self.find(id : Int32)
    new id, "Crystal Lang 101"
  end
  
  # These properties are exposed since they are either implicitly or expliticly a part of the `default` group.
  getter id : Int32
  getter name : String
  
  @[ASRA::Groups("default")]
  property? published : Bool = false
  
  # This property is not exposed since it is not part of the `default` group.
  @[ASRA::Groups("detailed")]
  getter body : String = "BODY"
  
  def initialize(@id : Int32, @name : String); end
end

class ArticleController < ATH::Controller
  @[ATHA::Post(path: "/publish/:id")]
  @[ATHA::View(status: :accepted, serialization_groups: ["default"])]
  def publish(id : Int32) : Article
    article = Article.find id
    article.published = true
    article
  end
end

ATH.run

# POST /publish/10 # => {"id":10,"name":"Crystal Lang 101","published":true} - 202
```

See the [API Docs][Athena::Serializer] for more detailed information, or [this forum post](https://forum.crystal-lang.org/t/athena-0-11-0/2627) for a quick overview.
