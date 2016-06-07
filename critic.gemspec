# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'critic/version'

Gem::Specification.new do |spec|
  spec.name          = 'critic'
  spec.version       = Critic::VERSION
  spec.authors       = ['Josh Lane']
  spec.email         = ['me@joshualane.com']

  spec.summary       = 'Resource authorization'
  spec.description   = 'Resource authorization via PORO'
  spec.homepage      = 'http://lanej.io/critic'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'

  spec.add_dependency 'activesupport', '> 3.0', '< 5.0'
end
