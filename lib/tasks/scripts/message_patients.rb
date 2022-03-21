class MessagePatients
  def self.call(*args)
    new(*args).call
  end

  attr_reader :patients, :message, :channel, :only_contactable, :dryrun, :verbose, :report
  VALID_CHANNELS = [:whatsapp, :sms]

  def initialize(patients, message, channel: :whatsapp, only_contactable: true, dryrun: false, verbose: true)
    @patients = patients
    @message = message
    @channel = channel
    @only_contactable = only_contactable
    @dryrun = dryrun
    @verbose = verbose
    @report = {}
  end

  def call
    unless patients.is_a?(ActiveRecord::Relation)
      raise ArgumentError, "Patients should be passed in as an ActiveRecord::Relation."
    end

    unless VALID_CHANNELS.include?(channel)
      raise ArgumentError, "Message channels can only be of types: #{VALID_CHANNELS}"
    end

    log("Total patients that will be contacted via #{channel}: #{contactable_patients.count}.")

    return if dryrun

    send_messages
    print_report
    self
  end

  private

  def send_messages
    contactable_patients.each do |patient|
      phone_number = phone_number_for(patient)
      next unless phone_number

      messaging_channel =
        if whatsapp?
          Messaging::Twilio::Whatsapp
        elsif sms?
          Messaging::Twilio::ReminderSms
        end

      begin
        communication = messaging_channel.send_message(recipient_number: phone_number, message: message)
      rescue Messaging::Twilio::Error
        update_report(:exception, patient: patient)
        next
      end
      update_report(:responses, communication: communication, patient: patient)
    end
  end

  def contactable_patients
    @contactable_patients ||= if only_contactable
      patients.contactable
    else
      patients
    end
  end

  def phone_number_for(patient)
    if only_contactable
      patient.latest_mobile_number
    else
      patient.latest_phone_number
    end
  end

  def whatsapp?
    channel == :whatsapp
  end

  def sms?
    channel == :sms
  end

  def update_report(response_type, params)
    status =
      case response_type
        when :exception
          response_type
        when :responses
          params[:communication].detailable.result
        else
          raise ArgumentError, "Invalid response_type for updating report: #{response_type}"
      end.to_sym

    @report[status] = [] unless @report[status].presence
    @report[status] << params[:patient].id
  end

  def print_report
    log("Delivery report:")
    @report.each_pair do |status, patients|
      log("#{status}:\t#{patients.count}")
    end
  end

  def log(message)
    puts "#{message}\n" if verbose
  end
end
