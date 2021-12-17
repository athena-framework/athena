require "./exclusion_strategy_interface"

# Allows creating different views of your objects by limiting which properties get serialized, based on the group(s) each property is a part of.
#
# It is enabled by default when using `ASR::Context#groups=`.
#
# ```
# class Example
#   include ASR::Serializable
#
#   def initialize; end
#
#   @[ASRA::Groups("list", "details")]
#   property id : Int64 = 1
#
#   @[ASRA::Groups("list", "details")]
#   property title : String = "TITLE"
#
#   @[ASRA::Groups("list")]
#   property comment_summaries : Array(String) = ["Sentence 1.", "Sentence 2."]
#
#   @[ASRA::Groups("details")]
#   property comments : Array(String) = ["Sentence 1.  Another sentence.", "Sentence 2.  Some other stuff."]
#
#   # Properties not explicitly given a group are added to the `"default"` group.
#   property created_at : Time = Time.utc(2019, 1, 1)
#   property updated_at : Time?
# end
#
# obj = Example.new
#
# ASR.serializer.serialize obj, :json, ASR::SerializationContext.new.groups = ["list"]            # => {"id":1,"title":"TITLE","comment_summaries":["Sentence 1.","Sentence 2."]}
# ASR.serializer.serialize obj, :json, ASR::SerializationContext.new.groups = ["details"]         # => {"id":1,"title":"TITLE","comments":["Sentence 1.  Another sentence.","Sentence 2.  Some other stuff."]}
# ASR.serializer.serialize obj, :json, ASR::SerializationContext.new.groups = ["list", "default"] # => {"id":1,"title":"TITLE","comment_summaries":["Sentence 1.","Sentence 2."],"created_at":"2019-01-01T00:00:00Z"}
# ```
struct Athena::Serializer::ExclusionStrategies::Groups
  include Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface

  @groups : Set(String)

  def initialize(groups : Enumerable(String))
    @groups = groups.to_set
  end

  def self.new(*groups : String)
    new groups
  end

  # :inherit:
  def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
    (metadata.groups & @groups).empty?
  end
end
