class CreateReportingMonths < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_months
  end
end
