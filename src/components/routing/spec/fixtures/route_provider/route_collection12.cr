true
####
Hash(String, Array(ART::RouteProvider::StaticRouteData)).new
####
{
  0 => ART.create_regex "^(?|(?i:([^\\.]++)\\.example\\.com)\\.(?|/abc([^/]++)(?|(*:55))))/?$",
}
####
{
  "55" => [
    { {"_route" => "r1"}, Set{"foo", "foo"}, nil, nil, false, true, nil },
    { {"_route" => "r2"}, Set{"foo", "foo"}, nil, nil, false, true, nil },
  ],
}
####
0
