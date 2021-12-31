false
####
{
  "/trailing/simple/no-methods"      => [{ {"_route" => "simple_trailing_slash_no_methods"}, nil, nil, nil, true, false, nil }],
  "/trailing/simple/get-method"      => [{ {"_route" => "simple_trailing_slash_GET_method"}, nil, Set{"GET"}, nil, true, false, nil }],
  "/trailing/simple/head-method"     => [{ {"_route" => "simple_trailing_slash_HEAD_method"}, nil, Set{"HEAD"}, nil, true, false, nil }],
  "/trailing/simple/post-method"     => [{ {"_route" => "simple_trailing_slash_POST_method"}, nil, Set{"POST"}, nil, true, false, nil }],
  "/not-trailing/simple/no-methods"  => [{ {"_route" => "simple_not_trailing_slash_no_methods"}, nil, nil, nil, false, false, nil }],
  "/not-trailing/simple/get-method"  => [{ {"_route" => "simple_not_trailing_slash_GET_method"}, nil, Set{"GET"}, nil, false, false, nil }],
  "/not-trailing/simple/head-method" => [{ {"_route" => "simple_not_trailing_slash_HEAD_method"}, nil, Set{"HEAD"}, nil, false, false, nil }],
  "/not-trailing/simple/post-method" => [{ {"_route" => "simple_not_trailing_slash_POST_method"}, nil, Set{"POST"}, nil, false, false, nil }],
}
####
{
  0 => ART::FastRegex.new "^(?|/trailing/regex/(?|no\\-methods/([^/]++)(*:46)|get\\-method/([^/]++)(*:73)|head\\-method/([^/]++)(*:101)|post\\-method/([^/]++)(*:130))|/not\\-trailing/regex/(?|no\\-methods/([^/]++)(*:183)|get\\-method/([^/]++)(*:211)|head\\-method/([^/]++)(*:240)|post\\-method/([^/]++)(*:269)))/?$",
}
####
{
  "46"  => [{ {"_route" => "regex_trailing_slash_no_methods"}, Set{"param"}, nil, nil, true, true, nil }],
  "73"  => [{ {"_route" => "regex_trailing_slash_GET_method"}, Set{"param"}, Set{"GET"}, nil, true, true, nil }],
  "101" => [{ {"_route" => "regex_trailing_slash_HEAD_method"}, Set{"param"}, Set{"HEAD"}, nil, true, true, nil }],
  "130" => [{ {"_route" => "regex_trailing_slash_POST_method"}, Set{"param"}, Set{"POST"}, nil, true, true, nil }],
  "183" => [{ {"_route" => "regex_not_trailing_slash_no_methods"}, Set{"param"}, nil, nil, false, true, nil }],
  "211" => [{ {"_route" => "regex_not_trailing_slash_GET_method"}, Set{"param"}, Set{"GET"}, nil, false, true, nil }],
  "240" => [{ {"_route" => "regex_not_trailing_slash_HEAD_method"}, Set{"param"}, Set{"HEAD"}, nil, false, true, nil }],
  "269" => [{ {"_route" => "regex_not_trailing_slash_POST_method"}, Set{"param"}, Set{"POST"}, nil, false, true, nil }],
}
####
0
