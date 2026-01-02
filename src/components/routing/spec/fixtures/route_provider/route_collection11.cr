false
####
Hash(String, Array(ART::RouteProvider::StaticRouteData)).new
####
{
  0 => ART.create_regex "^(?|/abc([^/]++)/(?|1(?|(*:27)|0(?|(*:38)|0(*:46)))|2(?|(*:59)|0(?|(*:70)|0(*:78)))))/?$",
}
####
{
  "27" => [{ART::Parameters.new({"_route" => "r1"}), Set{"foo"}, nil, nil, false, false, nil}],
  "38" => [{ART::Parameters.new({"_route" => "r10"}), Set{"foo"}, nil, nil, false, false, nil}],
  "46" => [{ART::Parameters.new({"_route" => "r100"}), Set{"foo"}, nil, nil, false, false, nil}],
  "59" => [{ART::Parameters.new({"_route" => "r2"}), Set{"foo"}, nil, nil, false, false, nil}],
  "70" => [{ART::Parameters.new({"_route" => "r20"}), Set{"foo"}, nil, nil, false, false, nil}],
  "78" => [{ART::Parameters.new({"_route" => "r200"}), Set{"foo"}, nil, nil, false, false, nil}],
}
####
0
