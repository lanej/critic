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
    include ActiveSupport::Callbacks

    if ActiveSupport::VERSION::MAJOR < 4
      define_callbacks :authorize, terminator: 'authorization.result == false || result == false'
    else
      define_callbacks :authorize, terminator: ->(target, result) { target.authorization.result == false || false == result }
    end
  end

  # Policy entry points
  module ClassMethods
    def authorize(action, subject, resource, args = nil)
      new(subject, resource).authorize(action, *args)
    end

    def scope(action = nil)
      action.nil? ? (@scope || :index) : (@scope = action)
    end

    def before_authorize(*names, &blk)
      _insert_callbacks(names, blk) do |name, options|
        set_callback(:authorize, :before, name, options)
      end
    end

    def after_authorize(*names, &blk)
      _insert_callbacks(names, blk) do |name, options|
        set_callback(:authorize, :after, name, options)
      end
    end

    def around_authorize(*names, &blk)
      _insert_callbacks(names, blk) do |name, options|
        set_callback(:authorize, :around, name, options)
      end
    end

    def skip_before_authorize(*names, &blk)
      _insert_callbacks(names, blk) do |name, options|
        skip_callback(:authorize, :before, name, options)
      end
    end

    # If :only or :except are used, convert the options into the
    # :unless and :if options of ActiveSupport::Callbacks.
    # The basic idea is that :only => :index gets converted to
    # :if => proc {|c| c.action_name == "index" }.
    #
    # ==== Options
    # * <tt>only</tt>   - The callback should be run only for this action
    # * <tt>except</tt>  - The callback should be run for all actions except this action
    def _normalize_callback_options(options)
      _normalize_callback_option(options, :only, :if)
      _normalize_callback_option(options, :except, :unless)
    end

    def _normalize_callback_option(options, from, to) # :nodoc:
      if from = options[from]
        from = Array(from).map { |o| "authorization.action.to_s == '#{o}'" }
        options[to] = Array(options[to]).unshift(from).join(" || ")
      end
    end

    # Skip before, after, and around action callbacks matching any of the names.
    #
    # ==== Parameters
    # * <tt>names</tt> - A list of valid names that could be used for
    #   callbacks. Note that skipping uses Ruby equality, so it's
    #   impossible to skip a callback defined using an anonymous proc
    #   using #skip_action_callback
    def skip_authorize(*names)
      skip_before_action(*names)
      skip_after_action(*names)
      skip_around_action(*names)
    end

    # Take callback names and an optional callback proc, normalize them,
    # then call the block with each callback. This allows us to abstract
    # the normalization across several methods that use it.
    #
    # ==== Parameters
    # * <tt>callbacks</tt> - An array of callbacks, with an optional
    #   options hash as the last parameter.
    # * <tt>block</tt>    - A proc that should be added to the callbacks.
    #
    # ==== Block Parameters
    # * <tt>name</tt>     - The callback to be added
    # * <tt>options</tt>  - A hash of options to be used when adding the callback
    def _insert_callbacks(callbacks, block = nil)
      options = callbacks.extract_options!
      _normalize_callback_options(options)
      callbacks.push(block) if block
      callbacks.each do |callback|
        yield callback, options
      end
    end
  end

  attr_reader :subject, :resource, :errors
  attr_accessor :authorization

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

    result = false

    begin
      run_callbacks(:authorize) do result = public_send(action, *args) end
    rescue Critic::AuthorizationDenied
      authorization.granted = false
    ensure
      authorization.result = result if authorization.result.nil?
    end

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
end
