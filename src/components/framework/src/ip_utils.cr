# Includes various IP address utility methods.
module Athena::Framework::IPUtils
  @@checked_ips = Hash(String, Bool).new

  # Returns `true` if the provided IPv4 or IPv6 *request_ip* is contained within the list of *ips* or subnets.
  def self.check(request_ip : String, ips : String | Enumerable(String)) : Bool
    ips = ips.is_a?(String) ? {ips} : ips

    is_ipv6 = request_ip.count(':') > 1

    ips.any? { |ip| is_ipv6 ? self.check_ipv6(request_ip, ip) : self.check_ipv4(request_ip, ip) }
  end

  # Returns `true` if *request_ip* matches *ip*, or is within the CIDR subnet.
  def self.check_ipv4(request_ip : String, ip : String) : Bool
    cache_key = "#{request_ip}-#{ip}-v4"

    self.get_cached_result(cache_key).try do |result|
      return result
    end

    unless request_ip_bytes = Socket::IPAddress.parse_v4_fields? request_ip
      return self.set_cached_result cache_key, false
    end

    if ip.includes? '/'
      address, netmask = ip.split '/', 2
      netmask = netmask.to_i

      if netmask.zero?
        return self.set_cached_result cache_key, Socket::IPAddress.valid_v4?(address)
      end

      if netmask < 0 || netmask > 32
        return self.set_cached_result cache_key, false
      end
    else
      address = ip
      netmask = 32
    end

    unless address_bytes = Socket::IPAddress.parse_v4_fields?(address)
      return self.set_cached_result cache_key, false
    end

    request_ip_decimal = IO::ByteFormat::BigEndian.decode(UInt32, request_ip_bytes.to_slice)
    address_decimal = IO::ByteFormat::BigEndian.decode(UInt32, address_bytes.to_slice)
    mask = UInt32::MAX << (32 - netmask)

    (request_ip_decimal & mask) == (address_decimal & mask)
  end

  # :ditto:
  def self.check_ipv6(request_ip : String, ip : String) : Bool
    cache_key = "#{request_ip}-#{ip}-v6"

    self.get_cached_result(cache_key).try do |result|
      return result
    end

    unless request_ip_bytes = Socket::IPAddress.parse_v6_fields? request_ip
      return self.set_cached_result cache_key, false
    end

    if ip.includes? '/'
      address, netmask = ip.split '/', 2
      netmask = netmask.to_i

      unless address_bytes = Socket::IPAddress.parse_v6_fields? address
        return self.set_cached_result cache_key, false
      end

      if netmask.zero?
        # If it made it this far `address_bytes` is valid so it would always be a valid IP
        return self.set_cached_result cache_key, true
      end

      if netmask < 1 || netmask > 128
        return self.set_cached_result cache_key, false
      end
    else
      unless address_bytes = Socket::IPAddress.parse_v6_fields? ip
        return self.set_cached_result cache_key, false
      end

      address = ip
      netmask = 128
    end

    0.upto(netmask // 16) do |i|
      left = netmask - 16 * i
      left = (left <= 16) ? left : 16
      mask = ~(0xFFFF >> left) & 0xFFFF

      if ((address_bytes[i]? || 0) & mask) != ((request_ip_bytes[i]? || 0) & mask)
        return self.set_cached_result cache_key, false
      end
    end

    self.set_cached_result cache_key, true
  end

  private def self.get_cached_result(key : String) : Bool?
    if @@checked_ips.has_key? key
      # Move the item last in the cache
      value = @@checked_ips[key]
      @@checked_ips.delete key
      return @@checked_ips[key] = value
    end

    nil
  end

  private def self.set_cached_result(key : String, value : Bool) : Bool
    @@checked_ips[key] = value
  end
end
