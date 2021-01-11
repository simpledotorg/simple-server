class SetMigratedPatientStatus < ActiveRecord::Migration[5.2]
  def up
    MarkMigratedPatient.call
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
