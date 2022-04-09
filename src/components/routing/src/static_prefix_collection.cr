class Athena::Routing::RouteProvider; end

# :nodoc:
class Athena::Routing::RouteProvider::StaticPrefixCollection
  # :nodoc:
  #
  # name, regex pattern, variables, route, trailing slash?, trailing var?
  record StaticPrefixTreeRoute, name : String, pattern : String, variables : Set(String), route : ART::Route, has_trailing_slash : Bool, has_trailing_var : Bool

  # :nodoc:
  record StaticTreeNamedRoute, name : String, route : ART::Route
  record StaticTreeName, name : String

  private alias RouteInfo = Array(StaticTreeNamedRoute | StaticPrefixTreeRoute | StaticTreeName | self)

  getter prefix : String
  getter items : RouteInfo = RouteInfo.new

  protected setter items : RouteInfo

  protected getter static_prefixes = Array(String).new
  protected getter prefixes = Array(String).new

  def initialize(@prefix : String = "/"); end

  # ameba:disable Metrics/CyclomaticComplexity
  def add_route(prefix : String, route : StaticTreeNamedRoute | StaticPrefixTreeRoute | StaticTreeName | self) : Nil
    prefix, static_prefix = self.common_prefix prefix, prefix

    idx = @items.size - 1
    while 0 <= idx
      item = @items[idx]

      common_prefix, common_static_prefix = self.common_prefix prefix, @prefixes[idx]

      if @prefix == common_prefix
        if @prefix != static_prefix && @prefix != @static_prefixes[idx]
          idx -= 1
          next
        end

        break if @prefix == static_prefix && @prefix == @static_prefixes[idx]
        break if @prefixes[idx] != @static_prefixes[idx] && @prefix == @static_prefixes[idx]
        break if prefix != static_prefix && @prefix == static_prefix

        idx -= 1

        next
      end

      if item.is_a? self && @prefixes[idx] == common_prefix
        item.add_route prefix, route
      else
        child = self.class.new common_prefix
        common_child_prefix, common_child_static_prefix = child.common_prefix @prefixes[idx], @prefixes[idx]
        child.prefixes << common_child_prefix
        child.static_prefixes << common_child_static_prefix

        common_child_prefix, common_child_static_prefix = child.common_prefix prefix, prefix
        child.prefixes << common_child_prefix
        child.static_prefixes << common_child_static_prefix

        child.items << @items[idx]
        child.items << route

        @static_prefixes[idx] = common_static_prefix
        @prefixes[idx] = common_prefix
        @items[idx] = child
      end

      return
    end

    @static_prefixes << static_prefix
    @prefixes << prefix
    @items << route
  end

  def populate_collection(routes : ART::RouteCollection) : ART::RouteCollection
    @items.each do |item|
      case item
      in ART::RouteProvider::StaticPrefixCollection then item.populate_collection routes
      in StaticTreeNamedRoute                       then routes.add item.name, item.route
      in StaticPrefixTreeRoute, StaticTreeName
        # Skip
      end
    end

    routes
  end

  # ameba:disable Metrics/CyclomaticComplexity
  protected def common_prefix(prefix : String, other_prefix : String) : Tuple(String, String)
    base_length = @prefix.size
    end_size = Math.min(prefix.size, other_prefix.size)
    static_length = nil

    idx = base_length
    begin
      while idx < end_size && prefix[idx] == other_prefix[idx]
        if '(' == prefix[idx]
          static_length = static_length || idx
          jdx = 1 + idx
          n = 1

          should_break = while jdx < end_size && 0 < n
            break true if prefix[jdx] != other_prefix[jdx]

            if '(' == prefix[jdx]
              n += 1
            elsif ')' == prefix[jdx]
              n -= 1
            elsif '\\' == prefix[jdx] && ((jdx += 1) == end_size || prefix[jdx] != other_prefix[jdx])
              jdx -= 1
              break false
            end

            jdx += 1
          end

          break if should_break
          break if 0 < n
          break if ('?' == (prefix[jdx]? || "") || '?' == (other_prefix[jdx]? || "")) && ((prefix[jdx]? || "") != (other_prefix[jdx]? || ""))

          sub_pattern = prefix[idx, jdx - idx]

          break if prefix != other_prefix && !sub_pattern.matches?(/^\(\[[^\]]++\]\+\+\)$/) && !"".matches?(/(?<!#{sub_pattern})/)

          idx = jdx - 1
        elsif '\\' == prefix[idx] && ((idx += 1) == end_size || prefix[idx] != other_prefix[idx])
          idx -= 1
          break
        end

        idx += 1
      end
    rescue e : ArgumentError
      raise e unless e.message.try &.starts_with? "lookbehind assertion is not fixed length"
    end

    {prefix[0, idx], prefix[0, static_length || idx]}
  end
end
