# frozen_string_literal: true
require 'critic/version'
require 'active_support/concern'
require 'active_support/callbacks'
require 'active_support/version'
require 'active_support/core_ext/string/inflections'

# Namespace
module Critic; end

Critic::Error = Class.new(StandardError)

Critic::AuthorizationMissing = Class.new(Critic::Error)

require 'critic/policy'
require 'critic/authorization'
require 'critic/authorization_denied'
require 'critic/controller'
require 'critic/callbacks'
