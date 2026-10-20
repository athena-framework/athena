# Raised in debug mode when the session is used while handling a request whose route is declared stateless.
class Athena::HTTPKernel::Exception::UnexpectedSessionUsage < Athena::HTTPKernel::Exception::Logic
end
