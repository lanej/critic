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

  describe '#authorize' do
    let!(:policy_class) { ChairPolicy.dup }

    it 'considers a nil return value as denied' do
      policy_class.class_eval do
        def action
          nil
        end
      end

      authorization = policy_class.new(nil, nil).authorize(:action)

      expect(authorization.result).to eq(nil)
      expect(authorization.granted).to eq(false)
    end

    it 'considers a false return value as denied' do
      policy_class.class_eval do
        def action
          false
        end
      end

      authorization = policy_class.new(nil, nil).authorize(:action)

      expect(authorization.result).to eq(false)
      expect(authorization.granted).to eq(false)
    end

    it 'considers an non-String return value as granted' do
      X = Struct.new(:attr)

      policy_class.class_eval do
        def action
          X.new(:test)
        end
      end

      authorization = policy_class.new(nil, nil).authorize(:action)

      expect(authorization.result).to eq(X.new(:test))
      expect(authorization.granted).to eq(true)
    end

    it 'considers a String return value as an error message and denies authorization' do
      policy_class.class_eval do
        def action
          "x"
        end
      end

      authorization = policy_class.new(nil, nil).authorize(:action)

      expect(authorization.result).to eq("x")
      expect(authorization.granted).to eq(false)
      expect(authorization.messages).to contain_exactly("x")
    end
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
