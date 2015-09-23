require 'spec_helper'

RSpec.describe 'controller' do
  Table = Struct.new(:id)
  User  = Struct.new(:name)

  class TablePolicy
    include Critic::Policy

    def show?
    end
  end

  class Controller
    include Critic::Controller

    def initialize(user)
      @user = user
    end

    def show
      authorize table

      table
    end

    protected

    def table
      Table.new(1)
    end

    def critic
      @user
    end
  end

  it "authorizes the table" do
    expect(Controller.new(User.new("steve")).show).to eq(Table.new(1))
  end
end
