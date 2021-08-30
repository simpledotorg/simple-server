class ExperimentResultsExportWorker
  include Sidekiq::Worker

  def perform(experiment_name)
    experiment = Experimentation::Experiment.find_by!(name: experiment_name)
    exporter = Experimentation::Export.new(experiment)
    exporter.write_csv
  end
end
