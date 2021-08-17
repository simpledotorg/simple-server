module Experimentation
  class DataExport
    require "csv"

    EXPANDABLE_COLUMNS = ["Communications", "Appointments", "Blood Pressures"]

    attr_reader :experiment_name, :recipient_email_address, :results

    def initialize(experiment_name, recipient_email_address)
      @experiment_name = experiment_name
      @recipient_email_address = recipient_email_address
    end

    def as_csv
      results_service = Results.new(experiment_name)
      results_service.aggregate_data
      @results = results_service.patient_data_aggregate
      create_csv
    end

    private

    def headers
      keys = results.first.keys
      keys.map do |key|
        if key.in?(EXPANDABLE_COLUMNS)
          largest_entry = results.max {|a,b| a[key].length <=> b[key].length }
          largest_entry[key].map(&:keys)
        else
          key
        end
      end.flatten
    end

    def create_csv
      CSV.generate(headers: true) do |csv|
        csv << headers
        results.each do |patient_data|
          EXPANDABLE_COLUMNS.each do |column|
            patient_data[column].each {|column_data| patient_data.merge!(column_data) }
          end
          csv << patient_data
        end
      end
    end

    def mail_csv
      mailer = ApplicationMailer.new
      email_params = {
        to: recipient_email_address,
        subject: "Experiment data export: #{experiment.name}",
        content_type: "multipart/mixed",
        body: "Please see attached CSV."
      }
      email = mailer.mail(email_params)
      filename = experiment.name.gsub(" ", "_")
      email.attachments[filename] = {
        mime_type: "text/csv",
        content: csv
      }
      email.deliver
    end
  end
end
