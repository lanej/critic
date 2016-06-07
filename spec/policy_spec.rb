# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'policies' do
  class ChairPolicy
    include Critic::Policy

    def update
      subject.grants.include?(resource)
    end

    def show
      'No peeking' unless subject.grants.include?(resource)
    end
  end

  class Subject < Struct.new(:grants)
    def grants
      super || []
    end
  end

  it 'grants access to an authorized user' do
    consumer = Subject.new([:blah])

    expect(ChairPolicy.authorize(:update, consumer, :blah)).to be_granted
  end

  it 'denies access to an unauthorized user' do
    consumer = Subject.new([])
    authorization = ChairPolicy.authorize(:show, consumer, :blah)

    expect(authorization).to be_denied
  end
end
