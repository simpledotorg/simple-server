class MarkAppointmentTypeAsNonNull < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:appointments, :appointment_type, false)
  end
end
