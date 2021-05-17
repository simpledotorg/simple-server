class RemoveIndexFromTreatmentGroups < ActiveRecord::Migration[5.2]
  def change
    remove_column :treatment_groups, :index, :integer, null: false
  end
end
