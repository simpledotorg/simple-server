class RemovePatientKeyFromCvdRisks < ActiveRecord::Migration[6.1]
  def up
    remove_reference :cvd_risks, :patient
  end

  def down
    add_reference :cvd_risks, :patient, null: false, foreign_key: true, type: :uuid
  end
end
