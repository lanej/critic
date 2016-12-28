# frozen_string_literal: true
# Custom error class for authorization failures
class Critic::AuthorizationDenied < Critic::Error
  DEFAULT_MESSAGE = 'Authorization denied'

  attr_reader :authorization

  def initialize(authorization)
    @authorization = authorization

    message = if authorization.messages.any?
                authorization.messages.join(',')
              else
                DEFAULT_MESSAGE
              end
    super(message)
  end
end
