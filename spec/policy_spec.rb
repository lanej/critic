# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Critic::Policy do
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

  describe '#for' do
    Chair = Class.new
    Unknown = Class.new
    Relation = Struct.new(:model_name)

    it 'uses the #model_name if applicable' do

      expect(Critic::Policy.for(Relation.new('Chair'))).to eq(ChairPolicy)

      expect {
        Critic::Policy.for(Relation.new('Unknown'))
      }.to raise_exception(NameError, /UnknownPolicy/)
    end

    it "uses the class' name if provided" do
      expect(Critic::Policy.for(Chair)).to eq(ChairPolicy)

      expect { Critic::Policy.for(Unknown) }.to raise_exception(NameError, /UnknownPolicy/)
    end

    it "uses the object's class" do

      expect(Critic::Policy.for(Chair.new)).to eq(ChairPolicy)
      expect { Critic::Policy.for(Unknown.new) }.to raise_exception(NameError, /UnknownPolicy/)
    end
  end
end
