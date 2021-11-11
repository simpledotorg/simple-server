class AddMaxPatientsPerDayToExperiment < ActiveRecord::Migration[5.2]
  def change
    add_column :experiments, :max_patients_per_day, :integer, default: 0
  end
end
