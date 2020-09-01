class AddColumnsToPrescriptionDrugs < ActiveRecord::Migration[5.2]
  def change
    add_column :prescription_drugs, :frequency, :string
    add_column :prescription_drugs, :duration_in_days, :integer
  end
end
