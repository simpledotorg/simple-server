class ExperimentResultsExportWorker
  include Sidekiq::Worker

  def perform(experiment_name, recipient_email_address)
    mailer = ExperimentResultsMailer.new(experiment_name, recipient_email_address)
    mailer.mail_csv
  end
end
