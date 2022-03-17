class Messaging::Channel
  # Note on error handling: Any messaging channel implementation should raise
  # errors from the channel's API as exceptions. This is to allow background jobs to
  # retry in case of network/limit errors. The error object should contains the reason of
  # failure if it was due to a known error so that users of the service can use it
  # to handle known errors properly.

  def initialize
    @metrics = Metrics.with_object(self)
  end

  attr_reader :metrics

  def self.send_message(*args)
    new.send_message(*args)
  end

  def send_message(recipient_number:, message:)
    raise NotImplementedError
  end

  # A channel supports one of the communication types enumerated in
  # Communication.communication_types.
  def communication_type
    raise NotImplementedError
  end

  # A channel supports recording the delivery's details.
  # It should also tie it to a Communication.
  def record_communication(recipient_number:, response:)
    raise NotImplementedError
  end

  def track_metrics(&block)
    metrics.increment("#{communication_type}.attempts")

    begin
      response = yield block
      metrics.increment("#{communication_type}.send")
      response
    rescue Messaging::Error => exception
      metrics.increment("#{communication_type}.errors")
      raise exception
    end
  end
end
