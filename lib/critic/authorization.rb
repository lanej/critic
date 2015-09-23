class Critic::Authorization
  def self.from(policy, action, result)
    errors = []

    case result
    when String
      errors << result
    when FalseClass
      errors << policy.failure_message(action)
    end

    Critic::Authorization.new(policy, action, errors)
  end

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
