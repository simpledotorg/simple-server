class Api::V4::FacilityMedicalOfficersController < APIController
  def sync_to_user
    facilities = trace_sync_data(
      "query_facility_medical_officers",
      resource: "facility_medical_officers"
    ) do |finish|
      records = current_facility_group.facilities
        .eager_load(teleconsultation_medical_officers: :phone_number_authentications)
        .to_a
      finish[:output_count] = records.size
      records
    end

    medical_officers = trace_sync_data(
      "transform_facility_medical_officers",
      resource: "facility_medical_officers",
      input_count: facilities.size
    ) do |finish|
      payload = facilities.map { |facility| facility_medical_officers(facility) }
      finish[:output_count] = payload.size
      payload
    end

    trace_sync_data(
      "render_pull_response",
      resource: "facility_medical_officers"
    ) do |finish|
      finish[:output_count] = medical_officers.size
      render json: to_response(medical_officers)
    end
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
