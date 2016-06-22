# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Critic::Controller' do
  before { Table.all.clear }

  let!(:user)       { User.new('steve') }
  let!(:controller) { TableController.new(user) }

  Table = Struct.new(:id)

  def Table.all
    @all ||= []
  end

  User = Struct.new(:name)

  class TablePolicy
    include Critic::Policy

    def destroy(options)
      options[:accept] == true
    end

    def show
      !subject.name.empty?
    end

    def update
      true
    end

    def index(match: /reject/)
      Table.all.select { |t| !t.id.to_s.match(match) }
    end
  end

  class TableController
    include Critic::Controller

    include ActiveSupport::Callbacks

    def initialize(user)
      @user = user
    end

    def update
      # looks like a rails controller action
      params[:action] = :update

      table.id = 2
      authorize table

      verify_authorized

      table
    end

    protected

    def table
      @table ||= Table.new(1)
    end

    def params
      @params ||= {}
    end

    def critic
      @user
    end
  end

  describe 'Rails' do
    it 'authorizes a single resource using contextual parameters' do
      expect(controller.update).to eq(Table.new(2))
    end
  end

  describe '#verify_authorized' do
    it 'raises if authorization was not performed' do
      expect {
        controller.send(:verify_authorized)
      }.to raise_exception(Critic::AuthorizationMissing)
    end

    it 'returns true if authorization is performed' do
      controller.send(:authorizing!)
      expect(controller.send(:verify_authorized)).to eq(true)
    end
  end

  describe '#authorized' do
    it 'returns a boolean matching authorization success' do
      user.name = 'steve'
      expect(controller.authorized?(Table.new(1), :show)).to eq(true)

      user.name = ''
      expect(controller.authorized?(Table.new(1), :show)).to eq(false)

      user.name = 'steve'
      allow(user).to receive(:name).and_raise(Critic::AuthorizationDenied.new(controller.send(:authorization)))
      expect(controller.authorized?(Table.new(1), :show)).to eq(false)
    end
  end

  describe '#authorize' do
    it 'passes #with to the policy as arguments' do
      expect(
        controller.authorize(Table.new(1), :destroy, with: {accept: true})
      ).to eq(true)

      expect {
        controller.authorize(Table.new(1), :destroy, with: {foo: false})
      }.to raise_exception(Critic::AuthorizationDenied)
    end
  end

  describe '#authorize_scope' do
    it 'authorizes resource scope and returns result' do
      [Table.new('1'), Table.new('reject'), Table.new('A')].each { |t| Table.all << t }

      expect(controller.authorize_scope(Table)).to contain_exactly(Table.new('1'), Table.new('A'))
    end

    it 'accepts with: arguments' do
      [Table.new('1'), Table.new('reject'), Table.new('A')].each { |t| Table.all << t }

      expect(controller.authorize_scope(Table, with: {match: 'A'})).to contain_exactly(Table.new('1'), Table.new('reject'))
    end
  end
end
