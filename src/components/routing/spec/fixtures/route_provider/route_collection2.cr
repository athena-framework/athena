true
####
{
  "/test/baz"      => [{ {"_route" => "baz"}, nil, nil, nil, false, false, nil }],
  "/test/baz.html" => [{ {"_route" => "baz2"}, nil, nil, nil, false, false, nil }],
  "/test/baz3"     => [{ {"_route" => "baz3"}, nil, nil, nil, true, false, nil }],
  "/foofoo"        => [{ {"_route" => "foofoo", "def" => "test"}, nil, nil, nil, false, false, nil }],
  "/spa ce"        => [{ {"_route" => "space"}, nil, nil, nil, false, false, nil }],
  "/multi/new"     => [{ {"_route" => "overridden2"}, nil, nil, nil, false, false, nil }],
  "/multi/hey"     => [{ {"_route" => "hey"}, nil, nil, nil, true, false, nil }],
  "/ababa"         => [{ {"_route" => "ababa"}, nil, nil, nil, false, false, nil }],
  "/route1"        => [{ {"_route" => "route1"}, "a.example.com", nil, nil, false, false, nil }],
  "/c2/route2"     => [{ {"_route" => "route2"}, "a.example.com", nil, nil, false, false, nil }],
  "/route4"        => [{ {"_route" => "route4"}, "a.example.com", nil, nil, false, false, nil }],
  "/c2/route3"     => [{ {"_route" => "route3"}, "b.example.com", nil, nil, false, false, nil }],
  "/route5"        => [{ {"_route" => "route5"}, "c.example.com", nil, nil, false, false, nil }],
  "/route6"        => [{ {"_route" => "route6"}, nil, nil, nil, false, false, nil }],
  "/route11"       => [{ {"_route" => "route11"}, /^(?P<var1>[^\.]++)\.example\.com$/i, nil, nil, false, false, nil }],
  "/route12"       => [{ {"_route" => "route12", "var1" => "val"}, /^(?P<var1>[^\.]++)\.example\.com$/i, nil, nil, false, false, nil }],
  "/route17"       => [{ {"_route" => "route17"}, nil, nil, nil, false, false, nil }],
  "/secure"        => [{ {"_route" => "secure"}, nil, nil, Set{"https"}, false, false, nil }],
  "/nonsecure"     => [{ {"_route" => "nonsecure"}, nil, nil, Set{"http"}, false, false, nil }],
}
####
{
  0 => ART.create_regex "^(?|(?:(?:[^./]*+\\.)++)(?|/foo/(baz|athenaa)(*:47)|/bar(?|/([^/]++)(*:70)|head/([^/]++)(*:90))|/test/([^/]++)(?|(*:115))|/([']+)(*:131)|/a/(?|b\"b/([^/]++)(?|(*:160)|(*:168))|(.*)(*:181)|b\"b/([^/]++)(?|(*:204)|(*:212)))|/multi/hello(?:/([^/]++))?(*:248)|/([^/]++)/b/([^/]++)(?|(*:279)|(*:287))|/aba/([^/]++)(*:309))|(?i:([^\\.]++)\\.example\\.com)\\.(?|/route1(?|3/([^/]++)(*:371)|4/([^/]++)(*:389)))|(?i:c\\.example\\.com)\\.(?|/route15/([^/]++)(*:441))|(?:(?:[^./]*+\\.)++)(?|/route16/([^/]++)(*:489)|/a/(?|a\\.\\.\\.(*:510)|b/(?|([^/]++)(*:531)|c/([^/]++)(*:549)))))/?$",
}
####
{
  "47"  => [{ {"_route" => "foo", "def" => "test"}, Set{"bar"}, nil, nil, false, true, nil }],
  "70"  => [{ {"_route" => "bar"}, Set{"foo"}, Set{"GET", "HEAD"}, nil, false, true, nil }],
  "90"  => [{ {"_route" => "barhead"}, Set{"foo"}, Set{"GET"}, nil, false, true, nil }],
  "115" => [
    { {"_route" => "baz4"}, Set{"foo"}, nil, nil, true, true, nil },
    { {"_route" => "baz5"}, Set{"foo"}, Set{"POST"}, nil, true, true, nil },
    { {"_route" => "baz.baz6"}, Set{"foo"}, Set{"PUT"}, nil, true, true, nil },
  ],
  "131" => [{ {"_route" => "quoter"}, Set{"quoter"}, nil, nil, false, true, nil }],
  "160" => [{ {"_route" => "foo1"}, Set{"foo"}, Set{"PUT"}, nil, false, true, nil }],
  "168" => [{ {"_route" => "bar1"}, Set{"bar"}, nil, nil, false, true, nil }],
  "181" => [{ {"_route" => "overridden"}, Set{"var"}, nil, nil, false, true, nil }],
  "204" => [{ {"_route" => "foo2"}, Set{"foo1"}, nil, nil, false, true, nil }],
  "212" => [{ {"_route" => "bar2"}, Set{"bar1"}, nil, nil, false, true, nil }],
  "248" => [{ {"_route" => "helloWorld", "who" => "World!"}, Set{"who"}, nil, nil, false, true, nil }],
  "279" => [{ {"_route" => "foo3"}, Set{"_locale", "foo"}, nil, nil, false, true, nil }],
  "287" => [{ {"_route" => "bar3"}, Set{"_locale", "bar"}, nil, nil, false, true, nil }],
  "309" => [{ {"_route" => "foo4"}, Set{"foo"}, nil, nil, false, true, nil }],
  "371" => [{ {"_route" => "route13"}, Set{"name", "var1"}, nil, nil, false, true, nil }],
  "389" => [{ {"_route" => "route14", "var1" => "val"}, Set{"name", "var1"}, nil, nil, false, true, nil }],
  "441" => [{ {"_route" => "route15"}, Set{"name"}, nil, nil, false, true, nil }],
  "489" => [{ {"_route" => "route16", "var1" => "val"}, Set{"name"}, nil, nil, false, true, nil }],
  "510" => [{ {"_route" => "a"}, Set(String).new, nil, nil, false, false, nil }],
  "531" => [{ {"_route" => "b"}, Set{"var"}, nil, nil, false, true, nil }],
  "549" => [{ {"_route" => "c"}, Set{"var"}, nil, nil, false, true, nil }],
}
####
0
