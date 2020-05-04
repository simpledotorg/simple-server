class AddRiskLevelToPatients < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :risk_level, :integer
  end
end
