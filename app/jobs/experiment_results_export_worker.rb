class ExperimentResultsExportWorker
  include Sidekiq::Worker

  def perform(experiment_name, recipient_email_address)
    experiment = Experimentation::Experiment.find_by!(name: experiment_name)
    exporter = Experimentation::Export.new(experiment)
    csv = exporter.as_csv
    mailer = ExperimentResultsMailer.new(csv, experiment_name, recipient_email_address)
    mailer.deliver_csv
  end
end
