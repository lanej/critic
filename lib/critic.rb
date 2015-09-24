require "critic/version"
require "active_support/concern"
require "active_support/core_ext/string/inflections"

module Critic; end

Critic::AuthorizationDenied = Class.new(StandardError)

require 'critic/policy'
require 'critic/authorization'
require 'critic/controller'
