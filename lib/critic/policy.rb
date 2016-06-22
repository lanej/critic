# frozen_string_literal: true
module Critic::Policy
  extend ActiveSupport::Concern

  def self.policies
    @_policies ||= Hash.new { |h, k| h[k.to_s] = nil }
  end

  # @fixme do we really wish to demodulize ?
  def self.resource_class_for(object)
    if object.respond_to?(:model_name)
      # used for pulling class out of ActiveRecord::Relation objects
      object.model_name
    elsif object.is_a?(Class)
      object.to_s.demodulize
    else
      object.class.to_s.demodulize
    end
  end

  def self.for(resource)
    resource_class = resource_class_for(resource)

    policies.fetch(resource_class) { "#{resource_class}Policy".constantize }
  end

  included do
    include Critic::Callbacks
  end

  # Policy entry points
  module ClassMethods
    def authorize(action, subject, resource, args = nil)
      new(subject, resource).authorize(action, *args)
    end

    def scope(action = nil)
      action.nil? ? (@scope || :index) : (@scope = action)
    end
  end

  attr_reader :subject, :resource, :errors
  attr_accessor :authorization

  delegate :messages, :metadata, to: :authorization

  def initialize(subject, resource)
    @subject = subject
    @resource = resource
    @errors = []
  end

  def failure_message(action)
    "#{subject} is not authorized to #{action} #{resource}"
  end

  def authorize(action, *args)
    self.authorization = Critic::Authorization.new(self, action)

    result = catch(:halt) { process_authorization(action, args) }

    authorization.result = result if authorization.result.nil?

    case authorization.result
    when Critic::Authorization
      # user has accessed authorization directly
    when String
      authorization.granted = false
      authorization.messages << result
    when nil, false
      authorization.granted = false
      authorization.messages << failure_message(action)
    else
      authorization.granted = true
    end

    authorization
  end

  protected

  def halt(*response)
    throw :halt, *response
  end

  private

  def process_authorization(action, args)
    public_send(action, *args)
  end
end
