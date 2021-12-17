class Group
  include ASR::Serializable

  def initialize; end

  @[ASRA::Groups("list", "details")]
  property id : Int64 = 1

  @[ASRA::Groups("list")]
  property comment_summaries : Array(String) = ["Sentence 1.", "Sentence 2."]

  @[ASRA::Groups("details")]
  property comments : Array(String) = ["Sentence 1.  Another sentence.", "Sentence 2.  Some other stuff."]

  property created_at : Time = Time.utc(2019, 1, 1)
end
