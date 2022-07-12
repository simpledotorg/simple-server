class Messaging::Error < StandardError
  def initialize(message)
    @message = message
  end

  attr_reader :message
end
