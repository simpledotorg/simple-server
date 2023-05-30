class AddEnableMonthlySuppliesReportsToFacilities < ActiveRecord::Migration[6.1]
  def change
    add_column :facilities, :enable_monthly_supplies_reports, :boolean, default: false, null: false
  end
end
