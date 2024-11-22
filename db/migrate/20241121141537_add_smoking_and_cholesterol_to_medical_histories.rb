class AddSmokingAndCholesterolToMedicalHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :medical_histories, :smoking, :text
    add_column :medical_histories, :cholesterol, :integer
  end
end
