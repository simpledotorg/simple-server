class AddDiagnosisTimestampsToMedicalHistories < ActiveRecord::Migration[6.1]
  def up
    add_column :medical_histories, :htn_diagnosed_at, :datetime
    add_column :medical_histories, :dm_diagnosed_at, :datetime
  end

  def down
    remove_column :medical_histories, :htn_diagnosed_at
    remove_column :medical_histories, :dm_diagnosed_at
  end
end
