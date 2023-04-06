false
####
{
  "/just_head"     => [{ {"_route" => "just_head"}, nil, Set{"HEAD"}, nil, false, false, nil }],
  "/head_and_get"  => [{ {"_route" => "head_and_get"}, nil, Set{"HEAD", "GET"}, nil, false, false, nil }],
  "/get_and_head"  => [{ {"_route" => "get_and_head"}, nil, Set{"GET", "HEAD"}, nil, false, false, nil }],
  "/post_and_head" => [{ {"_route" => "post_and_head"}, nil, Set{"POST", "HEAD"}, nil, false, false, nil }],
  "/put_and_post"  => [
    { {"_route" => "put_and_post"}, nil, Set{"PUT", "POST"}, nil, false, false, nil },
    { {"_route" => "put_and_get_and_head"}, nil, Set{"PUT", "GET", "HEAD"}, nil, false, false, nil },
  ],
}
####
Hash(Int32, Regex).new
####
Hash(String, Array(ART::RouteProvider::DynamicRouteData)).new
####
0
