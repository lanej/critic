module Critic::Policy
  extend ActiveSupport::Concern

  included do

  end

  module ClassMethods
    def authorize(action, subject, resource)
      policy_instance = self.new(subject, resource)

      Critic::Authorization.from(policy_instance, action, policy_instance.public_send("#{action}?"))
    end
  end

  attr_reader :subject, :resource

  def initialize(subject, resource)
    @subject, @resource = subject, resource
  end

  def failure_message(action)
    "#{subject.to_s} is not authorized to #{action} #{resource}"
  end
end
