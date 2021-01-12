class SetTransferredPatientStatus < ActiveRecord::Migration[5.2]
  def up
    MarkTransferredPatient.call
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
