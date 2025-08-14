class AddSmokelessTobaccoToMedicalHistories < ActiveRecord::Migration[6.1]
  def change
    add_column :medical_histories, :smokeless_tobacco, :string
  end
end
