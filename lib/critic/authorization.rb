class Critic::Authorization
  attr_reader :policy, :action
  attr_accessor :messages, :granted, :result

  def initialize(policy, action)
    @policy, @action = policy, action

    @granted, @result = nil
    @messages = []
  end

  def granted?
    true == @granted
  end

  def denied?
    false == @granted
  end
end
