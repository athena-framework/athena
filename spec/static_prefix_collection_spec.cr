require "./spec_helper"

struct StaticPrefixCollectionTest < ASPEC::TestCase
  @[DataProvider("route_provider")]
  def test_grouping(routes : Array(Tuple(String, String)), expected : String) : Nil
    collection = ART::RouteProvider::StaticPrefixCollection.new "/"

    routes.each do |(path, name)|
      static_prefix = (route = ART::Route.new(path)).compile.static_prefix
      collection.add_route static_prefix, ART::RouteProvider::StaticPrefixCollection::StaticTreeNamedRoute.new name, route
    end

    self.dump(collection).should eq expected
  end

  def route_provider : Hash
    {
      "simple - not nested" => {
        [
          {"/", "root"},
          {"/prefix/segment/", "prefix_segment"},
          {"/leading/segment/", "leading_segment"},
        ],
        "root\nprefix_segment\nleading_segment",
      },
      "simple - one level nesting" => {
        [
          {"/", "root"},
          {"/group/segment/", "nested_segment"},
          {"/group/thing/", "some_segment"},
          {"/group/other/", "other_segment"},
        ],
        "root\n/group/\n-> nested_segment\n-> some_segment\n-> other_segment",
      },
      "nested - small group" => {
        [
          {"/", "root"},
          {"/prefix/segment/", "prefix_segment"},
          {"/prefix/segment/bb", "leading_segment"},
        ],
        "root\n/prefix/segment/\n-> prefix_segment\n-> leading_segment",
      },
      "nested - contains item at intersection" => {
        [
          {"/", "root"},
          {"/prefix/segment/", "prefix_segment"},
          {"/prefix/segment/bb", "leading_segment"},
        ],
        "root\n/prefix/segment/\n-> prefix_segment\n-> leading_segment",
      },
      "Retains matching order within groups" => {
        [
          {"/group/aa/", "aa"},
          {"/group/bb/", "bb"},
          {"/group/cc/", "cc"},
          {"/(.*)", "root"},
          {"/group/dd/", "dd"},
          {"/group/ee/", "ee"},
          {"/group/ff/", "ff"},
        ],
        "/group/\n-> aa\n-> bb\n-> cc\nroot\n/group/\n-> dd\n-> ee\n-> ff",
      },
      "Retains complex matching order with groups at base" => {
        [
          {"/aaa/111/", "first_aaa"},
          {"/prefixed/group/aa/", "aa"},
          {"/prefixed/group/bb/", "bb"},
          {"/prefixed/group/cc/", "cc"},
          {"/prefixed/(.*)", "root"},
          {"/prefixed/group/dd/", "dd"},
          {"/prefixed/group/ee/", "ee"},
          {"/prefixed/", "parent"},
          {"/prefixed/group/ff/", "ff"},
          {"/aaa/222/", "second_aaa"},
          {"/aaa/333/", "third_aaa"},
        ],
        "/aaa/\n-> first_aaa\n-> second_aaa\n-> third_aaa\n/prefixed/\n-> /prefixed/group/\n-> -> aa\n-> -> bb\n-> -> cc\n-> root\n-> /prefixed/group/\n-> -> dd\n-> -> ee\n-> -> ff\n-> parent",
      },
      "Group regardless of segments" => {
        [
          {"/aaa-111/", "a1"},
          {"/aaa-222/", "a2"},
          {"/aaa-333/", "a3"},
          {"/group-aa/", "g1"},
          {"/group-bb/", "g2"},
          {"/group-cc/", "g3"},
        ],
        "/aaa-\n-> a1\n-> a2\n-> a3\n/group-\n-> g1\n-> g2\n-> g3",
      },
    }
  end

  private def dump(collection : ART::RouteProvider::StaticPrefixCollection, prefix : String = "") : String
    lines = [] of String

    collection.items.each do |item|
      if item.is_a? ART::RouteProvider::StaticPrefixCollection
        lines << "#{prefix}#{item.prefix}"
        lines << self.dump(item, "#{prefix}-> ")
      else
        lines << "#{prefix}#{item.name}"
      end
    end

    lines.join "\n"
  end
end
