class MessagePatients
  def self.call(*args)
    new(*args).call
  end

  attr_reader :patients, :message, :message_type, :dryrun, :verbose

  def initialize(patients, message, message_type: :whatsapp, dryrun: false, verbose: true)
    @patients = patients
    @message = message
    @message_type = message_type
    @dryrun = dryrun
    @verbose = verbose
    @result = {}
  end

  def call
    log "Total patients that will be contacted via #{message_type}: #{valid_patients}"

    return if dryrun

    send_message
  end

  private

  def send_message
    valid_patients.each do |patient|
      phone_number = patient.latest_phone_number

      response = if message_type == :whatsapp
                   NotificationService.new.send_whatsapp(phone_number, message)
                 elsif message_type == :sms
                   NotificationService.new.send_sms(phone_number, message)
                 else
                   raise ArgumentError, "Invalid communication_type #{message_type}"
                 end

      process_response(response)
    end
  end

  def valid_patients
    @valid_patients ||= patients.contactable
  end

  def process_response(patient, response)
    @result.merge(patient: response.status)
  end

  def print_result

  end

  def log(message)
    puts message if verbose
  end
end

MessagePatients.call(patients, message)
