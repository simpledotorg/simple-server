class NotNullableDatesOnExperiment < ActiveRecord::Migration[5.2]
  def change
    Experimentation::Experiment.where(start_date: nil).update_all(start_date: "2021-05-01")
    Experimentation::Experiment.where(end_date: nil).update_all(end_date: "2021-06-01")

    change_column_null :experiments, :start_date, false
    change_column_null :experiments, :end_date, false
  end
end
