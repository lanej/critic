module Critic::Policy
  extend ActiveSupport::Concern

  included do

  end

  module ClassMethods
    def authorize(action, subject, resource)
      policy_instance = self.new(subject, resource)
      result = policy_instance.public_send("#{action}?")
    end
  end

  attr_reader :subject, :resource

  def initialize(subject, resource)
    @subject, @resource = subject, resource
  end
end
