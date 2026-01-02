false
####
{
  "/just_head"     => [{ART::Parameters.new({"_route" => "just_head"}), nil, Set{"HEAD"}, nil, false, false, nil}],
  "/head_and_get"  => [{ART::Parameters.new({"_route" => "head_and_get"}), nil, Set{"HEAD", "GET"}, nil, false, false, nil}],
  "/get_and_head"  => [{ART::Parameters.new({"_route" => "get_and_head"}), nil, Set{"GET", "HEAD"}, nil, false, false, nil}],
  "/post_and_head" => [{ART::Parameters.new({"_route" => "post_and_head"}), nil, Set{"POST", "HEAD"}, nil, false, false, nil}],
  "/put_and_post"  => [
    {ART::Parameters.new({"_route" => "put_and_post"}), nil, Set{"PUT", "POST"}, nil, false, false, nil},
    {ART::Parameters.new({"_route" => "put_and_get_and_head"}), nil, Set{"PUT", "GET", "HEAD"}, nil, false, false, nil},
  ],
}
####
Hash(Int32, Regex).new
####
Hash(String, Array(ART::RouteProvider::DynamicRouteData)).new
####
0
