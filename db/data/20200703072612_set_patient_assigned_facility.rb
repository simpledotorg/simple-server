class SetPatientAssignedFacility < ActiveRecord::Migration[5.2]
  def up
    Patient.in_batches(of: 10_000) do |batch|
      batch.update_all("assigned_facility_id = registration_facility_id")
    end
  end

  def down
    Patient.in_batches(of: 10_000) do |batch|
      batch.update_all(assigned_facility_id: nil)
    end
  end
end
