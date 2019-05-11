module Athena::DI
  # :nodoc:
  abstract struct ServiceDefinition; end

  record Definition(T) < Athena::DI::ServiceDefinition, service : Service, tags : Array(String) = [] of String, shared : Bool = true, service_klass : T.class = T do
    def service
      return @service if T < Struct
      @shared ? @service : @service.dup
    end
  end
end
