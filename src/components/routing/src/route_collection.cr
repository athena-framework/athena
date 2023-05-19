# Represents a collection of `ART::Route`s.
# Provides a way to traverse, edit, remove, and access the stored routes.
#
# Each route has an associated name that should be unique.
# Adding another route with the same name will override the previous one.
#
# ## Route Priority
#
# When determining which route should match, the first matching route will win.
# For example, if two routes were added with variable parameters in the same location, the first one that was added would match regardless of what their requirements are.
# In most cases this will not be a problem, but in some cases you may need to ensure a particular route is checked first.
#
# The `priority` argument within `#add` can be used to control this order.
class Athena::Routing::RouteCollection
  include Enumerable({String, Athena::Routing::Route})
  include Iterable({String, Athena::Routing::Route})

  @routes = Hash(String, ART::Route).new
  protected getter priorities = Hash(String, Int32).new

  @sorted : Bool = false

  # :nodoc:
  def_clone

  # TODO: Support route aliases?

  # Returns the `ART::Action` with the provided *name*.
  #
  # Raises a `ART::Exception::RouteNotFound` if a route with the provided *name* does not exist.
  def [](name : String) : ART::Route
    self.routes.fetch(name) { raise ART::Exception::RouteNotFound.new "No route with the name '#{name}' exists." }
  end

  # Returns the `ART::Action` with the provided *name*, or `nil` if it does not exist.
  def []?(name : String) : ART::Route?
    self.routes[name]?
  end

  # Adds all the routes from the provided *collection* to this collection.
  def add(collection : self) : Nil
    @sorted = false

    # Remove the routes first so they are added to the end of the routes hash.
    collection.each do |name, route|
      self.delete name

      @routes[name] = route

      if priority = collection.priorities[name]?
        @priorities[name] = priority
      end
    end
  end

  # Adds the provided *route* with the provided *name* to this collection, optionally with the provided *priority*.
  def add(name : String, route : ART::Route, priority : Int32 = 0) : Nil
    self.delete name

    @routes[name] = route

    @priorities[name] = priority unless priority.zero?
  end

  def add_defaults(defaults : Hash(String, _)) : Nil
    return if defaults.empty?

    @routes.each_value do |route|
      route.add_defaults defaults
    end
  end

  # Adds a path *prefix* to all routes stored in this collection.
  # Optionally allows merging in additional *defaults* or *requirements*.
  def add_prefix(prefix : String, defaults : Hash(String, _) = Hash(String, String?).new, requirements : Hash(String, String | Regex) = Hash(String, String | Regex).new) : Nil
    prefix = prefix.strip.rstrip '/'
    return if prefix.empty?

    @routes.each_value do |route|
      route.path = "/#{prefix}#{route.path}"
      route.add_defaults defaults
      route.add_requirements requirements
    end
  end

  # Adds the provided *prefix* to the name of all routes stored within this collection.
  def add_name_prefix(prefix : String) : Nil
    prefixed_routes = Hash(String, ART::Route).new
    prefixed_priorities = Hash(String, Int32).new

    @routes.each do |name, route|
      prefixed_routes["#{prefix}#{name}"] = route

      if canonical_route = route.default "_canonical_route"
        route.set_default "_canonical_route", "#{prefix}#{canonical_route}"
      end

      if priority = @priorities[name]?
        prefixed_priorities["#{prefix}#{name}"] = priority
      end
    end

    # TODO: Support aliases?

    @routes = prefixed_routes
    @priorities = prefixed_priorities
  end

  # Merges the provided *requirements* into all routes stored within this collection.
  def add_requirements(requirements : Hash(String, Regex | String)) : Nil
    return if requirements.empty?

    @routes.each_value do |route|
      route.add_requirements requirements
    end
  end

  # Sets the host property of all routes stored in this collection.
  # Optionally allows merging in additional *defaults* or *requirements*.
  def set_host(host : String, defaults : Hash(String, _) = Hash(String, String?).new, requirements : Hash(String, String | Regex) = Hash(String, String | Regex).new) : Nil
    @routes.each_value do |route|
      route.host = host
      route.add_defaults defaults
      route.add_requirements requirements
    end
  end

  # Sets the scheme(s) of all routes stored within this collection.
  def schemes=(schemes : String | Enumerable(String)) : Nil
    @routes.each_value do |route|
      route.schemes = schemes
    end
  end

  # Sets the method(s) of all routes stored within this collection.
  def methods=(methods : String | Enumerable(String)) : Nil
    @routes.each_value do |route|
      route.methods = methods
    end
  end

  # Removes the routes with the provide *names*.
  def remove(*names : String) : Nil
    names.each { |n| self.remove n }
  end

  # Removes the route with the provide *name*.
  def remove(name : String) : Nil
    self.delete name
  end

  # Yields the name and `ART::Route` object for each registered route.
  def each(&) : Nil
    self.routes.each do |k, v|
      yield({k, v})
    end
  end

  # Returns an `Iterator` for each registered route.
  def each
    self.routes.each
  end

  # Returns the routes stored within this collection.
  def routes : Hash(String, ART::Route)
    if !@priorities.empty? && !@sorted
      insert_order = @routes.keys

      @routes
        .to_a
        .sort! do |(n1, r1), (n2, r2)|
          priority = (@priorities[n2]? || 0) <=> (@priorities[n1]? || 0)

          next priority unless priority.zero?

          insert_order.index!(n1) <=> insert_order.index!(n2)
        end
        .tap { @routes.clear }
        .each { |name, route| @routes[name] = route }

      @sorted = true
    end

    @routes
  end

  # Returns the number of routes stored within this collection.
  def size : Int
    self.routes.size
  end

  private def delete(name : String) : Nil
    @routes.delete name
    @priorities.delete name
  end
end
