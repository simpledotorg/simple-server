class PopulatePatientRiskLevels < ActiveRecord::Migration[5.1]
  def up
    totals = SetRiskLevel::Result.new(updates: 0, no_changes: 0)
    Patient.in_batches do |batch|
      result = SetRiskLevel.call(batch)
      totals.updates += result.updates
      totals.no_changes += result.no_changes
    end
    puts "Complete!"
    puts totals
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
