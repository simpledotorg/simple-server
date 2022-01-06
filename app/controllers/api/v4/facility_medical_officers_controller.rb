# frozen_string_literal: true

class Api::V4::FacilityMedicalOfficersController < APIController
  def sync_to_user
    medical_officers = current_facility_group.facilities
      .eager_load(teleconsultation_medical_officers: :phone_number_authentications)
      .map { |facility| facility_medical_officers(facility) }
    render json: to_response(medical_officers)
  end

  private

  def facility_medical_officers(facility)
    {id: facility.id,
     facility_id: facility.id,
     medical_officers: transform_medical_officers(facility.teleconsultation_medical_officers),
     created_at: Time.current,
     updated_at: Time.current,
     deleted_at: nil}
  end

  def transform_medical_officers(medical_officers)
    medical_officers.map do |medical_officer|
      Api::V4::TeleconsultationMedicalOfficerTransformer.to_response(medical_officer)
    end
  end

  def to_response(payload)
    {facility_medical_officers: payload}
  end
end
