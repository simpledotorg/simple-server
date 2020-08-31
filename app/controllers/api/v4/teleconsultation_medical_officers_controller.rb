class Api::V4::TeleconsultationMedicalOfficersController < Api::V4::SyncController
  def sync_to_user
    __sync_to_user__("teleconsultation_medical_officers")
  end

  private

  def records_to_sync
    current_facility_group.facilities
  end

  def transform_to_response(facility)
    {id: facility.id,
     facility_id: facility.id,
     medical_officers: to_response(facility.teleconsultation_medical_officers),
     created_at: Time.current,
     updated_at: Time.current,
     deleted_at: Time.current}
  end

  def to_response(medical_officers)
    medical_officers.map do |medical_officer|
      Api::V4::TeleconsultationMedicalOfficerTransformer.to_response(medical_officer)
    end
  end
end
