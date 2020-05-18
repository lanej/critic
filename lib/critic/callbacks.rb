# frozen_string_literal: true
# Adds callbacks to {Critic::Policy#authorize}
module Critic::Callbacks
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks

    if ActiveSupport::VERSION::MAJOR < 4
      define_callbacks :authorize,
                       terminator: 'authorization.result == false || result == false',
                       skip_after_callbacks_if_terminated: true
    elsif ActiveSupport::VERSION::MAJOR < 5
      define_callbacks :authorize,
                       terminator: ->(target, result) { target.authorization.result == false || false == result },
                       skip_after_callbacks_if_terminated: true
    else
      define_callbacks :authorize,
                       terminator: lambda { |target, result_lambda|
                                     target.authorization.result == false || result_lambda.call == false
                                   },
                       skip_after_callbacks_if_terminated: true
    end
  end

  # Adds callback management functions to {Critic::Policy}
  module ClassMethods
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
      from = options[from]
      return unless from

      actions = Array(options[to]) + Array(from)
      options[to] = lambda {
        actions.any? { |action|
          authorization.action.to_s == action.to_s
        }
      }
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

  def process_authorization(*)
    run_callbacks(:authorize) { super }
  end
end
