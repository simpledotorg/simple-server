class Messaging::AlphaSms::Sms < Messaging::Channel
  def self.communication_type
    Communication.communication_types[:sms]
  end

  def send_message(**opts, &with_communication_do)
    raise NotImplementedError
  end

end
