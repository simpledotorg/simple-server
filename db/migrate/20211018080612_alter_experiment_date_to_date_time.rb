class AlterExperimentDateToDateTime < ActiveRecord::Migration[5.2]
  def change
    change_column :experiments, :start_date, :datetime
    rename_column :experiments, :start_date, :start_time

    change_column :experiments, :end_date, :datetime
    rename_column :experiments, :end_date, :end_time
  end
end
