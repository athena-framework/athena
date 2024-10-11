struct Athena::Mercure::Update
  getter topics : Array(String)
  getter data : String
  getter? private : Bool
  getter id : String?
  getter type : String?
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
