class RemoveStateFromExperiment < ActiveRecord::Migration[5.2]
  def change
    remove_column :experiments, :state
    add_column :experiments, :deleted_at, :timestamp, required: false
  end
end
