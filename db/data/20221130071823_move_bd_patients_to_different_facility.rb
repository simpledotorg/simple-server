# frozen_string_literal: true

class MoveBdPatientsToDifferentFacility < ActiveRecord::Migration[6.1]
  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    Patient.where(
      registration_facility_id: "fe48375c-7826-41dd-9110-d716a9181e8f",
      registration_user_id: "ced029f9-4e06-40cd-b719-605c85a4b004"
    )
      .update_all(
        registration_facility_id: "daff41a3-4922-41b0-a822-6fef2db07e68",
        assigned_facility_id: "daff41a3-4922-41b0-a822-6fef2db07e68"
      )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
