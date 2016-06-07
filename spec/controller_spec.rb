# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'controller' do
  before do Table.all.clear end

  Table = Struct.new(:id)

  def Table.all
    @all ||= []
  end

  User = Struct.new(:name)

  class TablePolicy
    include Critic::Policy

    def show
      !subject.name.empty?
    end

    def index
      Table.all.select { |t| !t.id.to_s.match(/reject/) }
    end
  end

  class Controller
    include Critic::Controller

    def initialize(user)
      @user = user
    end

    def show
      authorize table, :show

      table
    end

    def index
      authorize_scope Table
    end

    protected

    def table
      Table.new(1)
    end

    def critic
      @user
    end
  end

  it 'authorizes the single resource' do
    expect(Controller.new(User.new('steve')).show).to eq(Table.new(1))
  end

  it 'authorizes resource scope' do
    [Table.new('1'), Table.new('reject'), Table.new('A')].each do |t| Table.all << t end

    expect(Controller.new(User.new('steve')).index).to contain_exactly(Table.new('1'), Table.new('A'))
  end
end
