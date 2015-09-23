module Critic::Policy
  extend ActiveSupport::Concern

  def self.policies
    @_policies ||= Hash.new { |h,k| h[k.to_s] = nil }
  end

  def self.for(resource)
    resource_class = resource.is_a?(Class) ? resource : resource.class

    policies.fetch(resource_class) { "#{resource_class}Policy".constantize }
  end

  included do

  end

  module ClassMethods
    def authorize(action, subject, resource, *args)
      self.new(subject, resource).authorize(action, *args)
    end

    def policy_for(*klasses)
      klasses.each { |klass|
        # @todo warn on re-definition
        Critic::Policy.policies[klass] ||= self
      }
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
