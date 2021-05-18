class CreateCalendarMonths < ActiveRecord::Migration[5.2]
  def change
    create_view :calendar_months
  end
end
