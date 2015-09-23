module Critic::Controller
  extend ActiveSupport::Concern

  included do
    if respond_to?(:hide_action)
      hide_action(:authorize)
    end
  end

  module ClassMethods
  end

  def authorize(resource, options={})
    action       = (defined?(params) && params.fetch(:action)) || (_,_,method = parse_caller(caller[0]); method)
    policy_class = options[:policy] || Critic::Policy.for(resource.class)
    args         = *options[:args]

    policy_class.authorize(action, critic, resource, *args)
  end

  protected

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
