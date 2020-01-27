class AddOpdLoadToFacility < ActiveRecord::Migration[5.1]
  def change
    add_column :facilities, :monthly_opd_load, :integer
  end
end
