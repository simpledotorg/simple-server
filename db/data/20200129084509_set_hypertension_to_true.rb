class SetHypertensionToTrue < ActiveRecord::Migration[5.1]
  def up
    MedicalHistory.in_batches(of: 1_000) do |batch|
      batch.update_all(hypertension: 'yes', diagnosed_with_hypertension: 'yes')
    end
  end

  def down
    Rails.logger.info 'This data migration cannot be reversed. Skipping.'
  end
end
