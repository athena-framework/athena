# Represents an update to publish.
#
# ```
# AMC::Update.new(
#   "https://example.com/books/1",
#   {status: "OutOfStock"}.to_json
# )
# ```
#
# The topic may be any string, but is recommended it be an [IRI (Internationalized Resource Identifier)](https://datatracker.ietf.org/doc/html/rfc3987) that uniquely identifies the resource the update related to.
# The data may also be any string, but will most commonly be JSON.
#
# ### Private Updates
#
# By default, an update would be sent to all subscribers listening on that topic.
# However, if `private: true` is defined on the update, then it'll only be sent to subscribers who are authorized to receive it.
# See [Authorization](/Mercure/#authorization) for more information.
struct Athena::Mercure::Update
  # Returns the identifiers this update is associated with.
  getter topics : Array(String)

  # Returns the string content of the update.
  getter data : String

  # If `true`, the update will not be sent to subscribers who are not authorized to receive it.
  getter? private : Bool

  # Maps to the SSE's [id](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#id) property.
  getter id : String?

  # Maps to the SSE's [event](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#event) property
  getter type : String?

  # Maps to the SSE's [retry](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#retry) property
  getter retry : Int32?

  def initialize(
    topics : String | Array(String),
    @data : String = "",
    @private : Bool = false,
    @id : String? = nil,
    @type : String? = nil,
    @retry : Int32? = nil,
  )
    @topics = topics.is_a?(String) ? [topics] : topics
  end
end
