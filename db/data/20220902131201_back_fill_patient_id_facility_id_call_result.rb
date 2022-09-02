class BackFillPatientIdFacilityIdCallResult < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE call_results SET (facility_id, patient_id) = (
        SELECT facility_id, patient_id FROM appointments
        WHERE call_results.appointment_id = appointments.id
      )
    SQL
    )
  end

  def down
    ActiveRecord::Base.connection.execute(<<-SQL
      UPDATE call_results SET (facility_id, patient_id) = (NULL, NULL)
    SQL
    )
  end
end
