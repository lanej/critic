# frozen_string_literal: true
require 'critic/version'
require 'active_support/concern'
require 'active_support/callbacks'
require 'active_support/version'
require 'active_support/core_ext/string/inflections'

# Namespace
module Critic; end

Critic::AuthorizationDenied  = Class.new(StandardError)
Critic::AuthorizationMissing = Class.new(StandardError)

require 'critic/policy'
require 'critic/authorization'
require 'critic/controller'
