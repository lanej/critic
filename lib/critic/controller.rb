# frozen_string_literal: true
module Critic::Controller
  extend ActiveSupport::Concern

  included do
    if respond_to?(:hide_action)
      hide_action(:authorize)
      hide_action(:authorize_scope)
    end
  end

  def authorize(resource, *args, **options)
    options[:action] ||= default_action || args.shift

    action       = options.fetch(:action)
    policy_class = options[:policy] || policy(resource)

    authorizing!

    @authorization = policy_class.authorize(action, critic, resource, *args)

    authorization_failed! if @authorization.denied?

    @authorization.result
  end

  def authorized?(resource, *args, **options)
    authorize(resource, *args, **options)
  rescue Critic::AuthorizationDenied
    false
  end

  def authorize_scope(scope, policy: policy(scope), **options)
    options[:action] ||= policy.scope

    authorize(scope, options)
  end

  protected

  attr_reader :authorization

  def authorization_failed!
    raise Critic::AuthorizationDenied, authorization.messages
  end

  def authorization_missing!
    raise Critic::AuthorizationMissing
  end

  def verify_authorized
    unless true == @_authorizing
      authorization_missing!
    else
      true
    end
  end

  def authorizing!
    @_authorizing = true
  end

  def policy(object)
    Critic::Policy.for(object)
  end

  def critic
    (defined?(consumer) && consumer) || current_user
  end

  private

  def default_action
    defined?(params) && params[:action]
  end
end
