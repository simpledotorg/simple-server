class AddMonthDateIndexReportingPrescriptions < ActiveRecord::Migration[6.1]
  self.disable_ddl_transaction = true

  def up
    add_index :reporting_prescriptions, [:month_date],
      name: "reporting_prescriptions_month_date", algorithm: :concurrently
  end

  def down
    remove_index :reporting_prescriptions,
      name: "reporting_prescriptions_month_date"
  end
end
