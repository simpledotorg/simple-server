class NotNullableDatesOnExperiment < ActiveRecord::Migration[5.2]
  def change
    change_column_null :experiments, :start_date, false
    change_column_null :experiments, :end_date, false
  end
end
