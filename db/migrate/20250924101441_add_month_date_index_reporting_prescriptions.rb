class AddMonthDateIndexReportingPrescriptions < ActiveRecord::Migration[6.1]
  def up
    add_index :reporting_prescriptions, [:month_date],
      name: "reporting_prescriptions_month_date"
  end

  def down
    remove_index :reporting_prescriptions,
      name: "reporting_prescriptions_month_date"
  end
end
