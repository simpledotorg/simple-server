class AddDiagnosisTimestampsToMedicalHistories < ActiveRecord::Migration[6.1]
  def up
    add_column :medical_histories, :htn_diagnosed_at, :datetime
    add_column :medical_histories, :dm_diagnosed_at, :datetime

    say_with_time "Backfilling diagnosis timestamps from device_created_at" do
      MedicalHistory.includes(:patient).find_each(batch_size: 1000) do |mh|
        next unless mh.patient && mh.device_created_at.present?

        htn_time = mh.device_created_at
        dm_time = mh.device_created_at

        next if htn_time.nil? && dm_time.nil?

        mh.update_columns(
          htn_diagnosed_at: htn_time,
          dm_diagnosed_at: dm_time
        )

        earliest = [htn_time, dm_time].compact.min
        mh.patient.update_columns(diagnosed_confirmed_at: earliest) if earliest
      end
    end
  end

  def down
    remove_column :medical_histories, :htn_diagnosed_at
    remove_column :medical_histories, :dm_diagnosed_at
  end
end
