class MakeEstimatedPopulationUniqueToRegionAndDiagnosis < ActiveRecord::Migration[5.2]
  def change
    remove_index :estimated_populations, :region_id
    add_index :estimated_populations, [:region_id, :diagnosis], unique: true
  end
end
