module Critic::Controller
  extend ActiveSupport::Concern

  included do
    if respond_to?(:hide_action)
      hide_action(:authorize)
      hide_action(:authorize_scope)
    end
  end

  module ClassMethods
  end

  def authorize(resource, options={})
    action       = options[:action] || (defined?(params) && params.fetch(:action)) || (_,_,method = parse_caller(caller[0]); method)
    policy_class = policy(resource, options)
    args         = *options[:args]

    @authorization = policy_class.authorize(action, critic, resource, *args)

    if @authorization.denied?
      authorization_failed!
    end

    @authorization
  end

  def authorize_scope(scope, options={})
    options[:action] ||= policy(scope, options).scope

    authorization = authorize(scope, options)

    authorization.result
  end

  protected

  attr_reader :authorization

  def authorization_failed!
    raise Critic::AuthorizationFailed.new(self.authorization.messages)
  end

  def policy(object, options={})
    options[:policy] || Critic::Policy.for(object)
  end

  def critic
    (defined?(consumer) && consumer) || current_user
  end

  def parse_caller(at)
    match_data = at.match(/^(.+?):(\d+)(?::in `(.*)')?/)

    if match_data
      _, file, line, method = match_data.to_a

      [file, line.to_i, method]
    end
  end
end
