false
####
{
  "/a/11"            => [{ {"_route" => "a_first"}, nil, nil, nil, false, false, nil }],
  "/a/22"            => [{ {"_route" => "a_second"}, nil, nil, nil, false, false, nil }],
  "/a/33"            => [{ {"_route" => "a_third"}, nil, nil, nil, false, false, nil }],
  "/a/44"            => [{ {"_route" => "a_fourth"}, nil, nil, nil, true, false, nil }],
  "/a/55"            => [{ {"_route" => "a_fifth"}, nil, nil, nil, true, false, nil }],
  "/a/66"            => [{ {"_route" => "a_sixth"}, nil, nil, nil, true, false, nil }],
  "/nested/group/a"  => [{ {"_route" => "nested_a"}, nil, nil, nil, true, false, nil }],
  "/nested/group/b"  => [{ {"_route" => "nested_b"}, nil, nil, nil, true, false, nil }],
  "/nested/group/c"  => [{ {"_route" => "nested_c"}, nil, nil, nil, true, false, nil }],
  "/slashed/group"   => [{ {"_route" => "slashed_a"}, nil, nil, nil, true, false, nil }],
  "/slashed/group/b" => [{ {"_route" => "slashed_b"}, nil, nil, nil, true, false, nil }],
  "/slashed/group/c" => [{ {"_route" => "slashed_c"}, nil, nil, nil, true, false, nil }],
}
####
{
  0 => ART.create_regex("^(?|/([^/]++)(*:16)|/nested/([^/]++)(*:39))/?$"),
}
####
{
  "16" => [{ {"_route" => "a_wildcard"}, Set{"param"}, nil, nil, false, true, nil }],
  "39" => [{ {"_route" => "nested_wildcard"}, Set{"param"}, nil, nil, false, true, nil }],
}
####
0
