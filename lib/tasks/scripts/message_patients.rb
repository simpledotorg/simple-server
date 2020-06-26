class MessagePatients
  def self.call(*args)
    new(*args).call
  end

  attr_reader :patients, :message, :whatsapp, :dryrun, :verbose, :report

  def initialize(patients, message, whatsapp: true, dryrun: false, verbose: true)
    @patients = patients
    @message = message
    @whatsapp = whatsapp
    @dryrun = dryrun
    @verbose = verbose
    @report = {}
  end

  def call
    unless patients.is_a?(ActiveRecord::Relation)
      raise ArgumentError, "Patients should be passed in as an ActiveRecord::Relation."
    end

    log("Total patients that will be contacted via #{whatsapp ? "whatsapp" : "sms"}: #{valid_patients.count}.")

    return if dryrun

    send_messages!
    print_report
    self
  end

  private

  def send_messages!
    valid_patients.each do |patient|
      phone_number = patient.latest_phone_number

      begin
        response =
          if whatsapp
            NotificationService
              .new
              .send_whatsapp(phone_number, message)
          else
            NotificationService
              .new
              .send_sms(phone_number, message)
          end
      rescue Twilio::REST::TwilioError => _
        update_report!(:exception, patient: patient)
      else
        update_report!(:responses, response: response, patient: patient)
      end
    end
  end

  def valid_patients
    @valid_patients ||= patients.contactable
  end

  def update_report!(response_type, params)
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

# MessagePatients.call(patients, message)
