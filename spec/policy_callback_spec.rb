# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Critic::Policy', 'callbacks' do
  let!(:policy) do
    Class.new do
      include Critic::Policy

      def show
        true
      end
    end
  end
  let!(:resource) { Struct.new(:id)  }

  def authorize(id, action: :show)
    policy.authorize(action, nil, resource.new(id)).result
  end

  it 'raises AuthorizationDenied if before_authorize hook returns false' do
    policy.before_authorize { |policy| nil }
    policy.before_authorize { |policy| "woo" }
    policy.before_authorize { |policy| policy.resource.id != 5 }

    expect(authorize(1)).to eq(true)
    expect(authorize(5)).to eq(false)
  end

  it 'does not raise AuthorizationDenied on after_authorize hooks' do
    policy.after_authorize { |policy| policy.resource.id.nil? }

    expect(authorize(5)).to eq(true)
    expect(authorize(nil)).to eq(true)
  end

  describe '#skip_before_authorize' do
    it 'accepts :only certain actions' do
      policy.class_eval do
        def condition
          false
        end

        def update
          true
        end
      end

      policy.before_authorize :condition

      expect(authorize(nil, action: :show)).to eq(false)
      expect(authorize(nil, action: :update)).to eq(false)

      policy.skip_before_authorize :condition, only: :update

      expect(authorize(nil, action: :show)).to eq(false)
      expect(authorize(nil, action: :update)).to eq(true)
    end
  end
end
