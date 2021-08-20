class ExperimentResultsMailer
  attr_reader :csv, :experiment_name, :recipient_email_address, :mailer

  def initialize(csv, experiment_name, recipient_email_address)
    @csv = csv
    @experiment_name = experiment_name
    @recipient_email_address = recipient_email_address
    @mailer = ApplicationMailer.new
  end

  def deliver_csv
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
      content: csv
    }
    email.deliver
  end
end
