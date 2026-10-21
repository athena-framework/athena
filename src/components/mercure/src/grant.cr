# Grants the *actions* on the *topics* to the holder of a JWT, such as subscribing to the updates of some topics.
#
# The *topics* are either a list of topics that are matched exactly, or a hash mapping a [topic matcher](https://mercure.rocks/spec#topic-selectors) type, such as `"urlpattern"`, to a list of patterns.
# Matcher types other than `"exact"` require the Mercure protocol 1.0.
#
# The optional *payload* is made available to the subscribers of the granted topics, so it requires the subscribe action.
# It is only supported by the Mercure protocol 1.0.
#
# ```
# AMC::Grant.new :subscribe, ["https://example.com/books/1"]
# AMC::Grant.new :subscribe, {"urlpattern" => ["https://example.com/books/:id"]}, JSON.parse(%({"user": "george"}))
# AMC::Grant.new AMC::Grant::Action.flags(Subscribe, Publish), ["https://example.com/chat"]
# ```
record Athena::Mercure::Grant,
  actions : Athena::Mercure::Grant::Action,
  topics : Array(String) | Hash(String, Array(String)),
  payload : JSON::Any? = nil do
  # The actions a grant may allow.
  @[Flags]
  enum Action
    # Subscribing to the updates of the granted topics.
    Subscribe

    # Publishing updates to the granted topics.
    Publish
  end

  # Returns grants from one of the shorthands accepted by `AMC::Authorization`:
  # a topic, a list of topics, or a hash of topic matchers to subscribe to, or the provided list of grants as is.
  def self.from(grants : Array(self) | Array(String) | Hash(String, Array(String)) | String) : Array(self)
    case grants
    in Array(self)
      grants
    in String
      [new(:subscribe, [grants])]
    in Array(String), Hash(String, Array(String))
      grants.empty? ? [] of self : [new(:subscribe, grants)]
    end
  end

  # :nodoc:
  #
  # Returns the topics as a hash of matcher types to the patterns of that type.
  def topics_by_matcher : Hash(String, Array(String))
    case topics = @topics
    in Array(String)
      topics.empty? ? {} of String => Array(String) : {"exact" => topics}
    in Hash(String, Array(String))
      topics
    end
  end

  # :nodoc:
  #
  # Returns `true` if at least one topic is granted, of any matcher type.
  def topics? : Bool
    self.topics_by_matcher.each_value.any? { |patterns| !patterns.empty? }
  end
end
