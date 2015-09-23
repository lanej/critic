module Critic::Policy
  extend ActiveSupport::Concern

  included do

  end

  module ClassMethods
    def authorize(action, subject, resource, *args)
      self.new(subject, resource).authorize(action, *args)
    end
  end

  attr_reader :subject, :resource, :errors

  def initialize(subject, resource)
    @subject, @resource = subject, resource
    @errors = []
  end

  def failure_message(action)
    "#{subject.to_s} is not authorized to #{action} #{resource}"
  end

  def authorize(action, *args)
    method = "#{action}?"

    result = public_send(method)

    case result
    when String
      errors << result
    when FalseClass
      errors << failure_message(action)
    end

    Critic::Authorization.new(self, action, errors)
  end
end
