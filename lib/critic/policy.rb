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

    def authorize_scope(subject, resource, *args)
      self.new(subject, resource).authorize_scope(*args)
    end

    def policy_for(*klasses)
      klasses.each { |klass|
        # @todo warn on re-definition
        Critic::Policy.policies[klass] ||= self
      }
    end

    def scope(action=nil)
      action.nil? ? (@scope || :index) : (@scope = action)
    end
  end

  attr_reader :subject, :resource, :errors
  attr_accessor :authorization

  def initialize(subject, resource)
    @subject, @resource = subject, resource
    @errors = []
  end

  def failure_message(action)
    "#{subject.to_s} is not authorized to #{action} #{resource}"
  end

  def authorize(action, *args)
    self.authorization = Critic::Authorization.new(self, action)

    granted, result = nil

    begin
      result = public_send(action)
    rescue Critic::AuthorizationDenied
      granted = false
    ensure
      self.authorization.result = result
    end


    case result
    when Critic::Authorization
      # user has accessed authorization directly
    when TrueClass
      self.authorization.granted = true
    when String
      self.authorization.granted = false
      self.authorization.messages << result
    when FalseClass
      self.authorization.granted = false
      self.authorization.messages << failure_message(action)
    end


    self.authorization
  end
end
