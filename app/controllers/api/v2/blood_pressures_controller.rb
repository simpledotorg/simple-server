class Api::V2::BloodPressuresController < Api::V3::BloodPressuresController
  include Api::V2::LogApiUsageByUsers

  private

  def transform_to_response(blood_pressure)
    Api::V2::BloodPressureTransformer.to_response(blood_pressure)
  end

  def blood_pressures_params
    params.require(:blood_pressures).map do |blood_pressure_params|
      blood_pressure_params.permit(
        :id,
        :systolic,
        :diastolic,
        :patient_id,
        :facility_id,
        :user_id,
        :created_at,
        :updated_at,
        :deleted_at
      )
    end
  end
end
