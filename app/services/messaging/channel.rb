class Messaging::Channel
  # Note on error handling: Any messaging channel implementation should raise
  # errors from the channel's API as exceptions. This is to allow background jobs to
  # retry in case of network/limit errors. The error object should contain the reason of
  # failure if it was due to a known error so that users of the service can use it
  # to handle known errors properly.

  def initialize
  end

  # The channel implementation is responsible for creating a Communication
  # and delivery details. This should return the communication object that was created.
  def self.send_message(...)
    new.send_message(...)
  end

  # A channel supports one of the communication types enumerated in
  # Communication.communication_types.
  def self.communication_type
    raise NotImplementedError
  end

  # Takes a block that is executed in a transaction with the communication creation.
  # This should be used when there are other associations (for example, notifications)
  # that need to be updated atomically.
  def send_message(**opts, &with_communication_do)
    raise NotImplementedError
  end

  def track_metrics(&block)
    Metrics.increment("#{self.class.communication_type}_attempts")

    begin
      response = yield block
      Metrics.increment("#{self.class.communication_type}_sent")
      response
    rescue Messaging::Error => exception
      Metrics.increment("#{self.class.communication_type}_errors")
      raise exception
    end
  end
end
