require "../spec_helper"

struct RequirementsTest < ASPEC::TestCase
  @[TestWith(
    {"FOO"},
    {"foo"},
    {"1987"},
    {"42-42"},
    {"for2o-bar"},
    {"foo-bA198r-Ccc"},
    {"for10O-bar-CCc-fooba187rccc"},
  )]
  def test_ascii_slug_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::ASCII_SLUG}).compile.regex
  end

  @[TestWith(
    {""},
    {"-"},
    {"fôo"},
    {"-FOO"},
    {"foo-"},
    {"-foo-"},
    {"-foo-bar-"},
    {"foo--bar"},
  )]
  def test_ascii_slug_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::ASCII_SLUG}).compile.regex
  end

  @[TestWith(
    {"foo"},
    {"foo/bar/ccc"},
    {"///"},
  )]
  def test_catch_all_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::CATCH_ALL}).compile.regex
  end

  @[TestWith(
    {""},
  )]
  def test_catch_all_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::CATCH_ALL}).compile.regex
  end

  @[TestWith(
    {"0000-01-01"},
    {"9999-12-31"},
    {"2022-04-15"},
    {"2024-02-29"},
    {"1243-04-31"},
  )]
  def test_date_ymd_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::DATE_YMD}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"0000-01-00"},
    {"9999-00-31"},
    {"2022-02-30"},
    {"2022-02-31"},
  )]
  def test_date_ymd_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::DATE_YMD}).compile.regex
  end

  @[TestWith(
    {"0"},
    {"012"},
    {"1"},
    {"42"},
    {"42198"},
    {"999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"},
  )]
  def test_digits_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::DIGITS}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"-1"},
    {"3.14"},
  )]
  def test_digits_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::DIGITS}).compile.regex
  end

  @[TestWith(
    {"1"},
    {"42"},
    {"42198"},
    {"999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999"},
  )]
  def test_positive_int_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::POSITIVE_INT}).compile.regex
  end

  @[TestWith(
    {""},
    {"0"},
    {"045"},
    {"foo"},
    {"-1"},
    {"3.14"},
  )]
  def test_positive_int_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::POSITIVE_INT}).compile.regex
  end

  @[TestWith(
    {"00000000000000000000000000"},
    {"ZZZZZZZZZZZZZZZZZZZZZZZZZZ"},
    {"01G0P4XH09KW3RCF7G4Q57ESN0"},
    {"05CSACM1MS9RB9H5F61BYA146Q"},
  )]
  def test_uid_base_32_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UID_BASE32}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"01G0P4XH09KW3RCF7G4Q57ESN"},
    {"01G0P4XH09KW3RCF7G4Q57ESNU"},
  )]
  def test_uid_base_32_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UID_BASE32}).compile.regex
  end

  @[TestWith(
    {"1111111111111111111111"},
    {"zzzzzzzzzzzzzzzzzzzzzz"},
    {"1BkPBX6T19U8TUAjBTtgwH"},
    {"1fg491dt8eQpf2TU42o2bY"},
  )]
  def test_uid_base_58_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UID_BASE58}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"1BkPBX6T19U8TUAjBTtgw"},
    {"1BkPBX6T19U8TUAjBTtgwI"},
  )]
  def test_uid_base_58_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UID_BASE58}).compile.regex
  end

  @[TestWith(
    {"00000000-0000-0000-0000-000000000000"},
    {"ffffffff-ffff-ffff-ffff-ffffffffffff"},
    {"01802c4e-c409-9f07-863c-f025ca7766a0"},
    {"056654ca-0699-4e16-9895-e60afca090d7"},
  )]
  def test_uid_rfc4122_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UID_RFC4122}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"01802c4e-c409-9f07-863c-f025ca7766a"},
    {"01802c4e-c409-9f07-863c-f025ca7766ag"},
    {"01802c4ec4099f07863cf025ca7766a0"},
  )]
  def test_uid_rfc4122_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UID_RFC4122}).compile.regex
  end

  @[TestWith(
    {"00000000000000000000000000"},
    {"7ZZZZZZZZZZZZZZZZZZZZZZZZZ"},
    {"01G0P4ZPM69QTD4MM4ENAEA4EW"},
  )]
  def test_ulid_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::ULID}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"8ZZZZZZZZZZZZZZZZZZZZZZZZZ"},
    {"01G0P4ZPM69QTD4MM4ENAEA4E"},
  )]
  def test_ulid_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::ULID}).compile.regex
  end

  @[TestWith(
    {"00000000-0000-1000-8000-000000000000"},
    {"ffffffff-ffff-8fff-bfff-ffffffffffff"},
    {"8c670a1c-bc95-11ec-8422-0242ac120002"},
    {"21902510-bc96-21ec-8422-0242ac120002"},
    {"61c86569-e477-3ed9-9e3b-1562edb03277"},
    {"e55a29be-ba25-46e0-a5e5-85b78a6f9a11"},
    {"bad98960-f1a1-530e-9a82-07d0b6c4e62f"},
    {"1ecbc9a8-432d-6b14-af93-715adc3b830c"},
    {"216fff40-98d9-71e3-a5e2-0800200c9a66"},
    {"216fff40-98d9-81e3-a5e2-0800200c9a66"},
  )]
  def test_uuid_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"01802c74-d78c-b085-0cdf-7cbad87c70a3"},
    {"e55a29be-bb25-46e0-a5e5-85b78a6f9a1"},
    {"e55a29bh-bb25-46e0-a5e5-85b78a6f9a11"},
    {"e55a29beba2546e0a5e585b78a6f9a11"},
  )]
  def test_uuid_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID}).compile.regex
  end

  @[TestWith(
    {"00000000-0000-1000-8000-000000000000"},
    {"ffffffff-ffff-1fff-bfff-ffffffffffff"},
    {"21902510-bc96-11ec-8422-0242ac120002"},
    {"a8ff8f60-088e-1099-a09d-53afc49918d1"},
    {"b0ac612c-9117-17a1-901f-53afc49918d1"},
  )]
  def test_uuid_v1_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V1}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"a3674b89-0170-3e30-8689-52939013e39c"},
    {"e0040090-3cb0-4bf9-a868-407770c964f9"},
    {"2e2b41d9-e08c-53d2-b435-818b9c323942"},
    {"2a37b67a-5eaa-6424-b5d6-ffc9ba0f2a13"},
  )]
  def test_uuid_v1_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V1}).compile.regex
  end

  @[TestWith(
    {"00000000-0000-3000-8000-000000000000"},
    {"ffffffff-ffff-3fff-bfff-ffffffffffff"},
    {"2b3f1427-33b2-30a9-8759-07355007c204"},
    {"c38e7b09-07f7-3901-843d-970b0186b873"},
  )]
  def test_uuid_v3_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V3}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"e24d9c0e-bc98-11ec-9924-53afc49918d1"},
    {"1c240248-7d0b-41a4-9d20-61ad2915a58c"},
    {"4816b668-385b-5a65-808d-bca410f45090"},
    {"1d2f3104-dff6-64c6-92ff-0f74b1d0e2af"},
  )]
  def test_uuid_v3_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V3}).compile.regex
  end

  @[TestWith(
    {"00000000-0000-4000-8000-000000000000"},
    {"ffffffff-ffff-4fff-bfff-ffffffffffff"},
    {"b8f15bf4-46e2-4757-bbce-11ae83f7a6ea"},
    {"eaf51230-1ce2-40f1-ab18-649212b26198"},
  )]
  def test_uuid_v4_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V4}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"15baaab2-f310-11d2-9ecf-53afc49918d1"},
    {"acd44dc8-d2cc-326c-9e3a-80a3305a25e8"},
    {"7fc2705f-a8a4-5b31-99a8-890686d64189"},
    {"1ecbc991-3552-6920-998e-efad54178a98"},
  )]
  def test_uuid_v4_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V4}).compile.regex
  end

  @[TestWith(
    {"00000000-0000-5000-8000-000000000000"},
    {"ffffffff-ffff-5fff-bfff-ffffffffffff"},
    {"49f4d32c-28b3-5802-8717-a2896180efbd"},
    {"58b3c62e-a7df-5a82-93a6-fbe5fda681c1"},
  )]
  def test_uuid_v5_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V5}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"b99ad578-fdd3-1135-9d3b-53afc49918d1"},
    {"b3ee3071-7a2b-3e17-afdf-6b6aec3acf85"},
    {"2ab4f5a7-6412-46c1-b3ab-1fe1ed391e27"},
    {"135fdd3d-e193-653e-865d-67e88cf12e44"},
  )]
  def test_uuid_v5_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V5}).compile.regex
  end

  @[TestWith(
    {"00000000-0000-6000-8000-000000000000"},
    {"ffffffff-ffff-6fff-bfff-ffffffffffff"},
    {"2c51caad-c72f-66b2-b6d7-8766d36c73df"},
    {"17941ebb-48fa-6bfe-9bbd-43929f8784f5"},
    {"1ecbc993-f6c2-67f2-8fbe-295ed594b344"},
  )]
  def test_uuid_v6_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V6}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"821040f4-7b67-12a3-9770-53afc49918d1"},
    {"802dc245-aaaa-3649-98c6-31c549b0df86"},
    {"92d2e5ad-bc4e-4947-a8d9-77706172ca83"},
    {"6e124559-d260-511e-afdc-e57c7025fed0"},
  )]
  def test_uuid_v6_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V6}).compile.regex
  end

  @[TestWith(
    {"00000000-0000-7000-8000-000000000000"},
    {"ffffffff-ffff-7fff-bfff-ffffffffffff"},
    {"216fff40-98d9-71e3-a5e2-0800200c9a66"},
  )]
  def test_uuid_v7_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V7}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"821040f4-7b67-12a3-9770-53afc49918d1"},
    {"802dc245-aaaa-3649-98c6-31c549b0df86"},
    {"92d2e5ad-bc4e-4947-a8d9-77706172ca83"},
    {"6e124559-d260-511e-afdc-e57c7025fed0"},
    {"17941ebb-48fa-6bfe-9bbd-43929f8784f5"},
    {"216fff40-98d9-81e3-a5e2-0800200c9a66"},
  )]
  def test_uuid_v7_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V7}).compile.regex
  end

  @[TestWith(
    {"00000000-0000-8000-8000-000000000000"},
    {"ffffffff-ffff-8fff-bfff-ffffffffffff"},
    {"216fff40-98d9-81e3-a5e2-0800200c9a66"},
  )]
  def test_uuid_v8_valid(path : String) : Nil
    "/#{path}".should match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V8}).compile.regex
  end

  @[TestWith(
    {""},
    {"foo"},
    {"821040f4-7b67-12a3-9770-53afc49918d1"},
    {"802dc245-aaaa-3649-98c6-31c549b0df86"},
    {"92d2e5ad-bc4e-4947-a8d9-77706172ca83"},
    {"6e124559-d260-511e-afdc-e57c7025fed0"},
    {"17941ebb-48fa-6bfe-9bbd-43929f8784f5"},
    {"216fff40-98d9-71e3-a5e2-0800200c9a66"},
  )]
  def test_uuid_v8_invalid(path : String) : Nil
    "/#{path}".should_not match ART::Route.new("/{path}", requirements: {"path" => ART::Requirement::UUID_V8}).compile.regex
  end
end
