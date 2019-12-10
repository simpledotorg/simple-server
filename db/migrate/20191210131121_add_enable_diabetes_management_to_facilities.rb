class AddEnableDiabetesManagementToFacilities < ActiveRecord::Migration[5.1]
  def change
    add_column :facilities, :enable_diabetes_management, :boolean, :default => false
    add_index :facilities, :enable_diabetes_management
  end
end
