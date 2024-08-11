require "./spec_helper"

struct ATH::HeaderUtilsTest < ASPEC::TestCase
  def test_separate_caches_per_protocol : Nil
    ip = "192.168.52.1"
    subnet = "192.168.0.0/16"

    ATH::IPUtils.check_ipv6(ip, subnet).should be_false
    ATH::IPUtils.check_ipv4(ip, subnet).should be_true

    ip = "2a01:198:603:0:396e:4789:8e99:890f"
    subnet = "2a01:198:603:0::/65"

    ATH::IPUtils.check_ipv4(ip, subnet).should be_false
    ATH::IPUtils.check_ipv6(ip, subnet).should be_true
  end

  @[DataProvider("ipv4_data")]
  def test_check_ipv4(is_match : Bool, remote_address : String, cidr : String | Array(String)) : Nil
    ATH::IPUtils.check(remote_address, cidr).should eq is_match
  end

  def ipv4_data : Tuple
    {
      {true, "192.168.1.1", "192.168.1.1"},
      {true, "192.168.1.1", "192.168.1.1/1"},
      {true, "192.168.1.1", "192.168.1.0/24"},
      {false, "192.168.1.1", "1.2.3.4/1"},
      {false, "192.168.1.1", "192.168.1.1/33"}, # invalid subnet
      {true, "192.168.1.1", ["1.2.3.4/1", "192.168.1.0/24"]},
      {true, "192.168.1.1", ["192.168.1.0/24", "1.2.3.4/1"]},
      {false, "192.168.1.1", ["1.2.3.4/1", "4.3.2.1/1"]},
      {true, "1.2.3.4", "0.0.0.0/0"},
      {true, "1.2.3.4", "192.168.1.0/0"},
      {false, "1.2.3.4", "256.256.256/0"}, # invalid CIDR notation
      {false, "an_invalid_ip", "192.168.1.0/24"},
      {false, "", "1.2.3.4/1"},
    }
  end

  @[DataProvider("ipv6_data")]
  def test_check_ipv6(is_match : Bool, remote_address : String, cidr : String | Array(String)) : Nil
    ATH::IPUtils.check(remote_address, cidr).should eq is_match
  end

  def ipv6_data : Tuple
    {
      {true, "2a01:198:603:0:396e:4789:8e99:890f", "2a01:198:603:0::/65"},
      {false, "2a00:198:603:0:396e:4789:8e99:890f", "2a01:198:603:0::/65"},
      {false, "2a01:198:603:0:396e:4789:8e99:890f", "::1"},
      {true, "0:0:0:0:0:0:0:1", "::1"},
      {false, "0:0:603:0:396e:4789:8e99:0001", "::1"},
      {true, "0:0:603:0:396e:4789:8e99:0001", "::/0"},
      {true, "0:0:603:0:396e:4789:8e99:0001", "2a01:198:603:0::/0"},
      {true, "2a01:198:603:0:396e:4789:8e99:890f", ["::1", "2a01:198:603:0::/65"]},
      {true, "2a01:198:603:0:396e:4789:8e99:890f", ["2a01:198:603:0::/65", "::1"]},
      {false, "2a01:198:603:0:396e:4789:8e99:890f", ["::1", "1a01:198:603:0::/65"]},
      {false, "}__test|O:21:&quot;JDatabaseDriverMysqli&quot;:3:{s:2", "::1"},
      {false, "2a01:198:603:0:396e:4789:8e99:890f", "unknown"},
      {false, "", "::1"},
      {false, "127.0.0.1", "::1"},
      {false, "0.0.0.0/8", "::1"},
      {false, "::1", "127.0.0.1"},
      {false, "::1", "0.0.0.0/8"},
      {true, "::ffff:10.126.42.2", "::ffff:10.0.0.0/0"},
    }
  end

  @[DataProvider("invalid_ip_address_data")]
  def test_invalid_ip_addresses(remote_address : String, cidr : String | Array(String)) : Nil
    ATH::IPUtils.check_ipv4(remote_address, cidr).should be_false
  end

  def invalid_ip_address_data : Hash
    {
      "invalid proxy wildcard"                         => {"192.168.20.13", "*"},
      "invalid proxy missing netmask"                  => {"192.168.20.13", "0.0.0.0"},
      "invalid request IP with invalid proxy wildcard" => {"0.0.0.0", "*"},
    }
  end

  @[DataProvider("ipv4_zero_mask_data")]
  def test_check_ipv4_zero_mask_data(is_match : Bool, remote_address : String, cidr : String | Array(String)) : Nil
    ATH::IPUtils.check_ipv4(remote_address, cidr).should eq is_match
  end

  def ipv4_zero_mask_data : Tuple
    {
      {true, "1.2.3.4", "0.0.0.0/0"},
      {true, "1.2.3.4", "192.168.1.0/0"},
      {false, "1.2.3.4", "256.256.256/0"}, # invalid CIDR notation
    }
  end
end
