class MessagePatients
  def self.call(*args)
    new(*args).call
  end

  attr_reader :patients, :message, :channel, :dryrun, :verbose, :report
  VALID_CHANNELS = [:whatsapp, :sms]

  def initialize(patients, message, channel: :whatsapp, dryrun: false, verbose: true)
    @patients = patients
    @message = message
    @channel = channel
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
      phone_number = patient.latest_mobile_number

      begin
        response =
          if whatsapp?
            NotificationService
              .new
              .send_whatsapp(phone_number, message)
          elsif sms?
            NotificationService
              .new
              .send_sms(phone_number, message)
          end
      rescue Twilio::REST::TwilioError
        update_report(:exception, patient: patient)
      else
        update_report(:responses, response: response, patient: patient)
      end
    end
  end

  def contactable_patients
    @contactable_patients ||= patients.contactable
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
          params[:response].status
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
