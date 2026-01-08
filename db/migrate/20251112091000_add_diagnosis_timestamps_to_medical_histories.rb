class AddDiagnosisTimestampsToMedicalHistories < ActiveRecord::Migration[6.1]
  def up
    add_column :medical_histories, :htn_diagnosed_at, :datetime
    add_column :medical_histories, :dm_diagnosed_at, :datetime

    say_with_time "Backfilling diagnosis timestamps for existing medical histories" do
      MedicalHistory.includes(:patient).find_each(batch_size: 1000) do |mh|
        next unless mh.patient

        htn_time =
          if %w[yes no].include?(mh.diagnosed_with_hypertension) ||
              %w[yes no].include?(mh.hypertension)
            mh.patient.recorded_at
          end

        dm_time =
          if %w[yes no].include?(mh.diabetes)
            mh.patient.recorded_at
          end

        next unless htn_time || dm_time

        mh.update_columns(
          htn_diagnosed_at: htn_time,
          dm_diagnosed_at: dm_time
        )
      end
    end
  end

  def down
    remove_column :medical_histories, :htn_diagnosed_at
    remove_column :medical_histories, :dm_diagnosed_at
  end
end
