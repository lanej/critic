class Critic::Authorization
  attr_reader :policy, :action, :errors

  def initialize(policy, action, errors=[])
    @policy, @action, @errors = policy, action, errors
  end

  def granted?
    errors.empty?
  end

  def void?
    errors.any?
  end
end
