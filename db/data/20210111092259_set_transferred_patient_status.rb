class SetTransferredPatientStatus < ActiveRecord::Migration[5.2]
  require "tasks/scripts/mark_transferred_patients"

  def up
    MarkTransferredPatient.call
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
