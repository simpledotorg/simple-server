class ExperimentResultsMailer
  attr_reader :experiment_name, :recipient_email_address, :mailer

  def initialize(experiment_name, recipient_email_address)
    @experiment_name = experiment_name
    @recipient_email_address = recipient_email_address
    @mailer = ApplicationMailer.new
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

  def csv_file
    results_service = Experimentation::Results.new(experiment_name)
    results_service.as_csv
  end
end
