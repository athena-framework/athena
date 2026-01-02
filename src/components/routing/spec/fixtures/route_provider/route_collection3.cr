false
####
{
  "/rootprefix/test" => [{ART::Parameters.new({"_route" => "static"}), nil, nil, nil, false, false, nil}],
  "/with-condition"  => [{ART::Parameters.new({"_route" => "with-condition"}), nil, nil, nil, false, false, 0}],
}
####
{
  0 => ART.create_regex "^(?|/rootprefix/([^/]++)(*:27))/?$",
}
####
{
  "27" => [{ART::Parameters.new({"_route" => "dynamic"}), Set{"var"}, nil, nil, false, true, nil}],
}
####
1
