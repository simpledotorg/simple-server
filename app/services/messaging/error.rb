class Messaging::Error < StandardError
  attr_reader :message, :reason
end
