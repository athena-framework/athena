true
####
{
  "/" => [
    { {"_route" => "a"}, /^(?P<d>[^\.]++)\.e\.c\.b\.a$/i, nil, nil, false, false, nil },
    { {"_route" => "c"}, /^(?P<e>[^\.]++)\.e\.c\.b\.a$/i, nil, nil, false, false, nil },
    { {"_route" => "b"}, "d.c.b.a", nil, nil, false, false, nil },
  ],
}
####
Hash(Int32, ART::FastRegex).new
####
Hash(String, Array(ART::RouteProvider::DynamicRouteData)).new
####
0
