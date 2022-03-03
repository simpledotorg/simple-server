class Messaging::Provider
# On Error Handling: Any messaging provider implementation should raise errors
# related to the provider's API as an exception. This is to allow background jobs to
# retry in case of network/limit errors. The error object should contains the reason of
# failure if it was due to a known error so that users of the service can use it
# to handle known errors properly.

  def initialize
    @metrics = Metrics.with_object(self)
  end

  attr_reader :metrics

  def send_message(recipient_number, message)
    # To be implemented by the individual provider.
  end

  def communication_type
    # A provider supports one of the communication types enumerated in
    # Communication.communication_types.
  end

  def track_metrics(&block)
    metrics.increment("#{communication_type}.attempts")

    begin
      yield block
      metrics.increment("#{communication_type}.send")
    rescue Messaging::Error => exception
      metrics.increment("#{communication_type}.errors")
      raise exception
    end
  end
end
