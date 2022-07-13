class Messaging::Error < StandardError
  def initialize(message)
    @message = message
    @reason = nil
  end

  attr_reader :message, :reason
end
