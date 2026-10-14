# The version of the [Mercure protocol](https://mercure.rocks/spec) a hub speaks.
enum Athena::Mercure::ProtocolVersion
  # The Mercure protocol 0.x, spoken by hubs before 1.0.
  Legacy

  # The Mercure protocol 1.0.
  V1

  # Returns the name of the cookie subscribers are authorized with by default.
  def default_cookie_name : String
    case self
    in .legacy? then "mercureAuthorization"
    in .v1?     then "__Secure-mercure_access_token"
    end
  end
end
