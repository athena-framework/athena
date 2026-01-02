true
####
{
  "/test/baz"      => [{ART::Parameters.new({"_route" => "baz"}), nil, nil, nil, false, false, nil}],
  "/test/baz.html" => [{ART::Parameters.new({"_route" => "baz2"}), nil, nil, nil, false, false, nil}],
  "/test/baz3"     => [{ART::Parameters.new({"_route" => "baz3"}), nil, nil, nil, true, false, nil}],
  "/foofoo"        => [{ART::Parameters.new({"_route" => "foofoo", "def" => "test"}), nil, nil, nil, false, false, nil}],
  "/spa ce"        => [{ART::Parameters.new({"_route" => "space"}), nil, nil, nil, false, false, nil}],
  "/multi/new"     => [{ART::Parameters.new({"_route" => "overridden2"}), nil, nil, nil, false, false, nil}],
  "/multi/hey"     => [{ART::Parameters.new({"_route" => "hey"}), nil, nil, nil, true, false, nil}],
  "/ababa"         => [{ART::Parameters.new({"_route" => "ababa"}), nil, nil, nil, false, false, nil}],
  "/route1"        => [{ART::Parameters.new({"_route" => "route1"}), "a.example.com", nil, nil, false, false, nil}],
  "/c2/route2"     => [{ART::Parameters.new({"_route" => "route2"}), "a.example.com", nil, nil, false, false, nil}],
  "/route4"        => [{ART::Parameters.new({"_route" => "route4"}), "a.example.com", nil, nil, false, false, nil}],
  "/c2/route3"     => [{ART::Parameters.new({"_route" => "route3"}), "b.example.com", nil, nil, false, false, nil}],
  "/route5"        => [{ART::Parameters.new({"_route" => "route5"}), "c.example.com", nil, nil, false, false, nil}],
  "/route6"        => [{ART::Parameters.new({"_route" => "route6"}), nil, nil, nil, false, false, nil}],
  "/route11"       => [{ART::Parameters.new({"_route" => "route11"}), /^(?P<var1>[^\.]++)\.example\.com$/i, nil, nil, false, false, nil}],
  "/route12"       => [{ART::Parameters.new({"_route" => "route12", "var1" => "val"}), /^(?P<var1>[^\.]++)\.example\.com$/i, nil, nil, false, false, nil}],
  "/route17"       => [{ART::Parameters.new({"_route" => "route17"}), nil, nil, nil, false, false, nil}],
}
####
{
  0 => ART.create_regex "^(?|(?:(?:[^./]*+\\.)++)(?|/foo/(baz|athenaa)(*:47)|/bar(?|/([^/]++)(*:70)|head/([^/]++)(*:90))|/test/([^/]++)(?|(*:115))|/([']+)(*:131)|/a/(?|b\"b/([^/]++)(?|(*:160)|(*:168))|(.*)(*:181)|b\"b/([^/]++)(?|(*:204)|(*:212)))|/multi/hello(?:/([^/]++))?(*:248)|/([^/]++)/b/([^/]++)(?|(*:279)|(*:287))|/aba/([^/]++)(*:309))|(?i:([^\\.]++)\\.example\\.com)\\.(?|/route1(?|3/([^/]++)(*:371)|4/([^/]++)(*:389)))|(?i:c\\.example\\.com)\\.(?|/route15/([^/]++)(*:441))|(?:(?:[^./]*+\\.)++)(?|/route16/([^/]++)(*:489)|/a/(?|a\\.\\.\\.(*:510)|b/(?|([^/]++)(*:531)|c/([^/]++)(*:549)))))/?$",
}
####
{
  "47"  => [{ART::Parameters.new({"_route" => "foo", "def" => "test"}), Set{"bar"}, nil, nil, false, true, nil}],
  "70"  => [{ART::Parameters.new({"_route" => "bar"}), Set{"foo"}, Set{"GET", "HEAD"}, nil, false, true, nil}],
  "90"  => [{ART::Parameters.new({"_route" => "barhead"}), Set{"foo"}, Set{"GET"}, nil, false, true, nil}],
  "115" => [
    {ART::Parameters.new({"_route" => "baz4"}), Set{"foo"}, nil, nil, true, true, nil},
    {ART::Parameters.new({"_route" => "baz5"}), Set{"foo"}, Set{"POST"}, nil, true, true, nil},
    {ART::Parameters.new({"_route" => "baz.baz6"}), Set{"foo"}, Set{"PUT"}, nil, true, true, nil},
  ],
  "131" => [{ART::Parameters.new({"_route" => "quoter"}), Set{"quoter"}, nil, nil, false, true, nil}],
  "160" => [{ART::Parameters.new({"_route" => "foo1"}), Set{"foo"}, Set{"PUT"}, nil, false, true, nil}],
  "168" => [{ART::Parameters.new({"_route" => "bar1"}), Set{"bar"}, nil, nil, false, true, nil}],
  "181" => [{ART::Parameters.new({"_route" => "overridden"}), Set{"var"}, nil, nil, false, true, nil}],
  "204" => [{ART::Parameters.new({"_route" => "foo2"}), Set{"foo1"}, nil, nil, false, true, nil}],
  "212" => [{ART::Parameters.new({"_route" => "bar2"}), Set{"bar1"}, nil, nil, false, true, nil}],
  "248" => [{ART::Parameters.new({"_route" => "helloWorld", "who" => "World!"}), Set{"who"}, nil, nil, false, true, nil}],
  "279" => [{ART::Parameters.new({"_route" => "foo3"}), Set{"_locale", "foo"}, nil, nil, false, true, nil}],
  "287" => [{ART::Parameters.new({"_route" => "bar3"}), Set{"_locale", "bar"}, nil, nil, false, true, nil}],
  "309" => [{ART::Parameters.new({"_route" => "foo4"}), Set{"foo"}, nil, nil, false, true, nil}],
  "371" => [{ART::Parameters.new({"_route" => "route13"}), Set{"name", "var1"}, nil, nil, false, true, nil}],
  "389" => [{ART::Parameters.new({"_route" => "route14", "var1" => "val"}), Set{"name", "var1"}, nil, nil, false, true, nil}],
  "441" => [{ART::Parameters.new({"_route" => "route15"}), Set{"name"}, nil, nil, false, true, nil}],
  "489" => [{ART::Parameters.new({"_route" => "route16", "var1" => "val"}), Set{"name"}, nil, nil, false, true, nil}],
  "510" => [{ART::Parameters.new({"_route" => "a"}), Set(String).new, nil, nil, false, false, nil}],
  "531" => [{ART::Parameters.new({"_route" => "b"}), Set{"var"}, nil, nil, false, true, nil}],
  "549" => [{ART::Parameters.new({"_route" => "c"}), Set{"var"}, nil, nil, false, true, nil}],
}
####
0
