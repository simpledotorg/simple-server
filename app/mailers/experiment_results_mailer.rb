class ExperimentResultsMailer
  require "csv"

  attr_reader :experiment_name, :recipient_email_address, :mailer, :results

  def initialize(experiment_name, recipient_email_address)
    @experiment_name = experiment_name
    @recipient_email_address = recipient_email_address
    @mailer = ApplicationMailer.new
    fetch_results
  end

  def mail_csv
    email_params = {
      to: recipient_email_address,
      subject: "Experiment data export: #{experiment_name}",
      content_type: "multipart/mixed",
      body: "Please see attached CSV."
    }
    email = mailer.mail(email_params)
    filename = experiment_name.tr(" ", "_") + ".csv"
    email.attachments[filename] = {
      mime_type: "text/csv",
      content: csv_file
    }
    email.deliver
  end

  private

  def fetch_results
    results_service = Experimentation::Results.new(experiment_name)
    results_service.aggregate_data
    @results = results_service.patient_data_aggregate
  end

  def csv_file
    CSV.generate(headers: true) do |csv|
      csv << headers
      results.each do |patient_data|
        Experimentation::Results::EXPANDABLE_COLUMNS.each do |column|
          patient_data[column].each { |column_data| patient_data.merge!(column_data) }
        end
        csv << patient_data
      end
    end
  end

  def headers
    # raise error if there are no Experimentation::
    keys = results.first.keys
    keys.map do |key|
      if key.in?(Experimentation::Results::EXPANDABLE_COLUMNS)
        largest_entry = results.max { |a, b| a[key].length <=> b[key].length }
        largest_entry[key].map(&:keys)
      else
        key
      end
    end.flatten
  end
end
