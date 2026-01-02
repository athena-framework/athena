false
####
{
  "/trailing/simple/no-methods"      => [{ART::Parameters.new({"_route" => "simple_trailing_slash_no_methods"}), nil, nil, nil, true, false, nil}],
  "/trailing/simple/get-method"      => [{ART::Parameters.new({"_route" => "simple_trailing_slash_GET_method"}), nil, Set{"GET"}, nil, true, false, nil}],
  "/trailing/simple/head-method"     => [{ART::Parameters.new({"_route" => "simple_trailing_slash_HEAD_method"}), nil, Set{"HEAD"}, nil, true, false, nil}],
  "/trailing/simple/post-method"     => [{ART::Parameters.new({"_route" => "simple_trailing_slash_POST_method"}), nil, Set{"POST"}, nil, true, false, nil}],
  "/not-trailing/simple/no-methods"  => [{ART::Parameters.new({"_route" => "simple_not_trailing_slash_no_methods"}), nil, nil, nil, false, false, nil}],
  "/not-trailing/simple/get-method"  => [{ART::Parameters.new({"_route" => "simple_not_trailing_slash_GET_method"}), nil, Set{"GET"}, nil, false, false, nil}],
  "/not-trailing/simple/head-method" => [{ART::Parameters.new({"_route" => "simple_not_trailing_slash_HEAD_method"}), nil, Set{"HEAD"}, nil, false, false, nil}],
  "/not-trailing/simple/post-method" => [{ART::Parameters.new({"_route" => "simple_not_trailing_slash_POST_method"}), nil, Set{"POST"}, nil, false, false, nil}],
}
####
{
  0 => ART.create_regex "^(?|/trailing/regex/(?|no\\-methods/([^/]++)(*:46)|get\\-method/([^/]++)(*:73)|head\\-method/([^/]++)(*:101)|post\\-method/([^/]++)(*:130))|/not\\-trailing/regex/(?|no\\-methods/([^/]++)(*:183)|get\\-method/([^/]++)(*:211)|head\\-method/([^/]++)(*:240)|post\\-method/([^/]++)(*:269)))/?$",
}
####
{
  "46"  => [{ART::Parameters.new({"_route" => "regex_trailing_slash_no_methods"}), Set{"param"}, nil, nil, true, true, nil}],
  "73"  => [{ART::Parameters.new({"_route" => "regex_trailing_slash_GET_method"}), Set{"param"}, Set{"GET"}, nil, true, true, nil}],
  "101" => [{ART::Parameters.new({"_route" => "regex_trailing_slash_HEAD_method"}), Set{"param"}, Set{"HEAD"}, nil, true, true, nil}],
  "130" => [{ART::Parameters.new({"_route" => "regex_trailing_slash_POST_method"}), Set{"param"}, Set{"POST"}, nil, true, true, nil}],
  "183" => [{ART::Parameters.new({"_route" => "regex_not_trailing_slash_no_methods"}), Set{"param"}, nil, nil, false, true, nil}],
  "211" => [{ART::Parameters.new({"_route" => "regex_not_trailing_slash_GET_method"}), Set{"param"}, Set{"GET"}, nil, false, true, nil}],
  "240" => [{ART::Parameters.new({"_route" => "regex_not_trailing_slash_HEAD_method"}), Set{"param"}, Set{"HEAD"}, nil, false, true, nil}],
  "269" => [{ART::Parameters.new({"_route" => "regex_not_trailing_slash_POST_method"}), Set{"param"}, Set{"POST"}, nil, false, true, nil}],
}
####
0
