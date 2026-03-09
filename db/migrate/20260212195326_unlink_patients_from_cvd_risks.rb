class UnlinkPatientsFromCvdRisks < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :cvd_risks, :patients
  end
end
