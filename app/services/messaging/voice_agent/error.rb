class Messaging::VoiceAgent::Error < Messaging::Error
  def initialize(message, reason: nil)
    @message = "Error while calling voice agent API: #{message}"
    @reason = reason
  end

  attr_reader :message, :reason
end
