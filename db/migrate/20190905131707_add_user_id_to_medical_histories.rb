class AddUserIdToMedicalHistories < ActiveRecord::Migration[5.1]
  def change
    add_column :medical_histories, :user_id, :uuid, index: true, null: true
  end
end
