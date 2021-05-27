class CreateReportingCalendarMonths < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_calendar_months
  end
end
