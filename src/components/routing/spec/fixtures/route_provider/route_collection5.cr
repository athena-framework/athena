false
####
{
  "/a/11"            => [{ART::Parameters.new({"_route" => "a_first"}), nil, nil, nil, false, false, nil}],
  "/a/22"            => [{ART::Parameters.new({"_route" => "a_second"}), nil, nil, nil, false, false, nil}],
  "/a/33"            => [{ART::Parameters.new({"_route" => "a_third"}), nil, nil, nil, false, false, nil}],
  "/a/44"            => [{ART::Parameters.new({"_route" => "a_fourth"}), nil, nil, nil, true, false, nil}],
  "/a/55"            => [{ART::Parameters.new({"_route" => "a_fifth"}), nil, nil, nil, true, false, nil}],
  "/a/66"            => [{ART::Parameters.new({"_route" => "a_sixth"}), nil, nil, nil, true, false, nil}],
  "/nested/group/a"  => [{ART::Parameters.new({"_route" => "nested_a"}), nil, nil, nil, true, false, nil}],
  "/nested/group/b"  => [{ART::Parameters.new({"_route" => "nested_b"}), nil, nil, nil, true, false, nil}],
  "/nested/group/c"  => [{ART::Parameters.new({"_route" => "nested_c"}), nil, nil, nil, true, false, nil}],
  "/slashed/group"   => [{ART::Parameters.new({"_route" => "slashed_a"}), nil, nil, nil, true, false, nil}],
  "/slashed/group/b" => [{ART::Parameters.new({"_route" => "slashed_b"}), nil, nil, nil, true, false, nil}],
  "/slashed/group/c" => [{ART::Parameters.new({"_route" => "slashed_c"}), nil, nil, nil, true, false, nil}],
}
####
{
  0 => ART.create_regex("^(?|/([^/]++)(*:16)|/nested/([^/]++)(*:39))/?$"),
}
####
{
  "16" => [{ART::Parameters.new({"_route" => "a_wildcard"}), Set{"param"}, nil, nil, false, true, nil}],
  "39" => [{ART::Parameters.new({"_route" => "nested_wildcard"}), Set{"param"}, nil, nil, false, true, nil}],
}
####
0
