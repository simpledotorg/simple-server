class CleanUpBadObservations < ActiveRecord::Migration[5.2]
  def up
    Encounter.with_discarded.discarded.in_batches(of: 1_000) do |batch|
      batch.each do |encounter|
        encounter.observations&.update_all(deleted_at: encounter.deleted_at)
      end
    end
  end

  def down
    Rails.logger.info "This data migration cannot be reversed. Skipping."
  end
end
