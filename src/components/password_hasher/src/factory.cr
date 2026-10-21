# Returns the `APH::Interface` configured for a user, based on its type.
#
# Password hashers are configured by type, or by name for an `APH::PasswordHasherAwareInterface` user to choose them.
# A type matches its subtypes and includers too, and the first hasher whose type matches a user is used.
# Types may be provided as is, or as their fully qualified name.
#
# ```
# factory = APH::Factory.new({
#   AdminUser                               => APH::Native.new(cost: 15),
#   APH::PasswordAuthenticatedUserInterface => APH::Native.new,
#   "strong"                                => APH::Native.new(cost: 16),
# })
#
# factory.password_hasher AdminUser.new # => The cost 15 hasher
# factory.password_hasher User.new      # => The default hasher
# factory.password_hasher "strong"      # => The cost 16 hasher
# ```
#
# NOTE: The configured types of a generic user type are only matched by the name of its instantiation, e.g. `"GenericUser(Int32)"`.
class Athena::PasswordHasher::Factory
  include Athena::PasswordHasher::FactoryInterface

  @password_hashers = {} of String => APH::Interface

  def initialize(password_hashers : Hash(K, V)) forall K, V
    password_hashers.each do |key, hasher|
      @password_hashers[key.to_s] = hasher
    end
  end

  # :inherit:
  def password_hasher(user : APH::PasswordAuthenticatedUserInterface) : APH::Interface
    self.user_password_hasher user
  end

  # :inherit:
  def password_hasher(user : APH::PasswordHasherAwareInterface) : APH::Interface
    self.user_password_hasher user
  end

  # :inherit:
  def password_hasher(name : String) : APH::Interface
    @password_hashers[name]? || raise APH::Exception::Runtime.new %(No password hasher has been configured for account "#{name}".)
  end

  private def user_password_hasher(user) : APH::Interface
    if user.is_a?(APH::PasswordHasherAwareInterface) && (hasher_name = user.password_hasher_name)
      return @password_hashers[hasher_name]? || raise APH::Exception::Runtime.new %(The password hasher "#{hasher_name}" was not configured.)
    end

    type_names = self.type_names user.class.name

    @password_hashers.each do |key, hasher|
      return hasher if type_names.includes? key
    end

    raise APH::Exception::Runtime.new %(No password hasher has been configured for account "#{user.class}".)
  end

  # Returns the names of the user type with the provided *type_name*, and of its ancestors.
  # They are generated at compile time for every type including the user interfaces, as types cannot be inspected at runtime.
  private def type_names(type_name : String) : Array(String)
    {% begin %}
      {%
        types = [] of Nil
        modules = [APH::PasswordAuthenticatedUserInterface, APH::PasswordHasherAwareInterface]

        # Modules including the user interfaces are added to the list being iterated, so that their includers are handled too.
        modules.each do |mod|
          mod.includers.each do |includer|
            if includer.module?
              modules << includer unless modules.includes? includer
            else
              types << includer
              includer.all_subclasses.each { |subclass| types << subclass }
            end
          end
        end
      %}

      case type_name
      {% for type in types.uniq %}
        when {{type.stringify}} then {{([type] + type.ancestors).map(&.stringify)}}
      {% end %}
      else
        [type_name]
      end
    {% end %}
  end
end
