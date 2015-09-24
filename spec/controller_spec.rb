require 'spec_helper'

RSpec.describe 'controller' do
  before { Table.all.clear }

  Table = Struct.new(:id)

  def Table.all
    @all ||= []
  end

  User  = Struct.new(:name)

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
      authorize table

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

  it "authorizes the single resource" do
    expect(Controller.new(User.new("steve")).show).to eq(Table.new(1))
  end

  it "authorizes resource scope" do
    [Table.new("1"), Table.new("reject"), Table.new("A")].each { |t| Table.all << t }

    expect(Controller.new(User.new("steve")).index).to contain_exactly(Table.new("1"), Table.new("A"))
  end
end
