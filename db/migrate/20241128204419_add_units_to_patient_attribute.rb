class AddUnitsToPatientAttribute < ActiveRecord::Migration[6.1]
  def change
    add_column :patient_attributes, :height_unit, :string
    add_column :patient_attributes, :weight_unit, :string
  end
end
