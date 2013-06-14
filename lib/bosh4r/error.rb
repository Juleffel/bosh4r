module Bosh4r
  class Error < StandardError; end
  class InitiateError < Error; end
  class AuthenticateError < Error; end
  class RestartError < Error; end
  class BindError < Error; end
  class RequestSessionError < Error; end
end
