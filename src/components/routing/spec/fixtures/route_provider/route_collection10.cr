false
####
Hash(String, Array(ART::RouteProvider::StaticRouteData)).new
####
{
  0 => ART.create_regex "^(?|/(en|fr)/(?|admin/post(?|(*:32)|/(?|new(*:46)|(\\d+)(*:58)|(\\d+)/edit(*:75)|(\\d+)/delete(*:94)))|blog(?|(*:110)|/(?|rss\\.xml(*:130)|p(?|age/([^/]++)(*:154)|osts/([^/]++)(*:175))|comments/(\\d+)/new(*:202)|search(*:216)))|log(?|in(*:234)|out(*:245)))|/(en|fr)?(*:264))/?$",
}
####
{
  "32"  => [{ {"_route" => "a", "_locale" => "en"}, Set{"_locale"}, nil, nil, true, false, nil }],
  "46"  => [{ {"_route" => "b", "_locale" => "en"}, Set{"_locale"}, nil, nil, false, false, nil }],
  "58"  => [{ {"_route" => "c", "_locale" => "en"}, Set{"_locale", "id"}, nil, nil, false, true, nil }],
  "75"  => [{ {"_route" => "d", "_locale" => "en"}, Set{"_locale", "id"}, nil, nil, false, false, nil }],
  "94"  => [{ {"_route" => "e", "_locale" => "en"}, Set{"_locale", "id"}, nil, nil, false, false, nil }],
  "110" => [{ {"_route" => "f", "_locale" => "en"}, Set{"_locale"}, nil, nil, true, false, nil }],
  "130" => [{ {"_route" => "g", "_locale" => "en"}, Set{"_locale"}, nil, nil, false, false, nil }],
  "154" => [{ {"_route" => "h", "_locale" => "en"}, Set{"_locale", "page"}, nil, nil, false, true, nil }],
  "175" => [{ {"_route" => "i", "_locale" => "en"}, Set{"_locale", "page"}, nil, nil, false, true, nil }],
  "202" => [{ {"_route" => "j", "_locale" => "en"}, Set{"_locale", "id"}, nil, nil, false, false, nil }],
  "216" => [{ {"_route" => "k", "_locale" => "en"}, Set{"_locale"}, nil, nil, false, false, nil }],
  "234" => [{ {"_route" => "l", "_locale" => "en"}, Set{"_locale"}, nil, nil, false, false, nil }],
  "245" => [{ {"_route" => "m", "_locale" => "en"}, Set{"_locale"}, nil, nil, false, false, nil }],
  "264" => [{ {"_route" => "n", "_locale" => "en"}, Set{"_locale"}, nil, nil, false, true, nil }],
}
####
0
