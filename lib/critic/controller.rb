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
    policy_class = policy(resource, options)

    authorizing!

    @authorization = policy_class.authorize(action, critic, resource, *args)

    authorization_failed! if @authorization.denied?

    @authorization.result
  end

  def authorize_scope(scope, options = {})
    options[:action] ||= policy(scope, options).scope

    authorize(scope, options)
  end

  protected

  attr_reader :authorization

  def authorization_failed!
    raise Critic::AuthorizationFailed, authorization.messages
  end

  def authorization_missing!
    raise Critic::AuthorizationMissing
  end

  def verify_authorized
    authorization_missing! unless true == @_authorizing
  end

  def authorizing!
    @_authorizing = true
  end

  def policy(object, options = {})
    options[:policy] || Critic::Policy.for(object)
  end

  def critic
    (defined?(consumer) && consumer) || current_user
  end

  private

  def default_action
    defined?(params) && params[:action]
  end
end
