# frozen_string_literal: true
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc 'Run rubocop'
task :rubocop do
  task = RuboCop::RakeTask.new
  task.patterns = ["lib/**/*.rb"]
  task
end
