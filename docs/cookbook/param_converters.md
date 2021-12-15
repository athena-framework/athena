[Param Converters][Athena::Framework::ParamConverter] allow applying custom logic in order to convert one or more primitive request arguments into a more complex type.

## DB

In a REST API, endpoints usually contain a reference to the `id` of the object in question; e.x. `GET /user/10`. A useful converter would be able to extract this ID from the path, lookup the related entity, and provide that object directly to the controller action. This reduces the boilerplate associated with doing a DB lookup within every controller action. It also makes testing easier as it abstract the logic of _how_ that object is resolved from what should be done to it.

NOTE: This example uses the `Granite` ORM, but should work with others.

```crystal
# Define an register our param converter as a service.
@[ADI::Register]
class DBConverter < ATH::ParamConverter
  # :inherit:
  #
  # Be sure to handle any possible exceptions here to return more helpful errors to the client.
  def apply(request : ATH::Request, configuration : Configuration(Entity)) : Nil forall Entity
    # Grab the `id` path parameter from the request's attributes as an Int32.
    primary_key = request.attributes.get "id", Int32

    # Raise a `404` error if a record with the provided ID does not exist.
    # This assumes there is a `.find` method on the related entity class.
    unless entity = Entity.find primary_key
      raise ATH::Exceptions::NotFound.new "An item with the provided ID could not be found"
    end

    # Set the resolved entity within the request's attributes
    # with a key matching the name of the argument within the converter annotation.
    request.attributes.set configuration.name, entity, Entity
  end
end

class Article < Granite::Base
  connection "default"
  table "articles"

  column id : Int64, primary: true
  column title : String
end

@[ATHA::Prefix("article")]
class ExampleController < ATH::Controller
  @[ATHA::Get("/:id")]
  @[ATHA::ParamConverter("article", converter: DBConverter)]
  def get_article(article : Article) : Article
    # Nothing else to do except return the related article.
    article
  end
end

# Run the server
ATH.run

# GET /article/1    # => {"id":1,"title":"Article A"}
# GET /article/5    # => {"id":5,"title":"Article E"}
# GET /article/-123 # => {"code":404,"message":"An item with the provided ID could not be found."}
```

Tada. We now have testable, reusable logic to provide database objects directly as arguments to our controller action. This converter technically supports any type that has a `.find` class method that returns an instance of that class. However, we can make the converter more strict by checking the type of the `Entity` free variable and raise a compile time error if it is not a child of `Granite::Base`. This can be accomplished by adding adding the following line to the `#apply` method:

```crystal
def apply(request : ATH::Request, configuration : Configuration(Entity)) : Nil forall Entity
  {% Entity.raise "DBConverter does not support arguments of type '#{Entity}'." unless Entity <= Granite::Base %}
  
  # Rest of method is unchanged
end
```
