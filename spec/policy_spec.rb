require 'spec_helper'

RSpec.describe 'policies' do
  class ChairPolicy
    include Critic::Policy

    def update?
      subject.grants.include?(resource)
    end
  end

  class Subject < Struct.new(:grants)
    def grants
      @grants || []
    end
  end

  it "grants access to an authorized user" do
    consumer = Subject.new([:blah])

    expect(ChairPolicy.authorize(:update, consumer, :blah))
  end
end
