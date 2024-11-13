class AddSmokingAndBmiToMedicalHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :medical_histories, :bmi, :integer
    add_column :medical_histories, :is_smoking, :boolean
  end
end
