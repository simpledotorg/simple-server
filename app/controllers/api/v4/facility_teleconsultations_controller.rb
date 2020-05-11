class Api::V4::FacilityTeleconsultationsController < APIController
  before_action :set_facility
  before_action :validate_teleconsultation_facility_belongs_to_users_facility_group

  attr_reader :facility

  def show
    render json: { teleconsultation_phone_number: teleconsultation_phone_number }
  end

  private

  def teleconsultation_phone_number
    phone_number = Phonelib.parse(facility.teleconsultation_isd_code.to_s + facility.teleconsultation_phone_number.to_s)

    phone_number.full_e164 if
      facility.teleconsultation_isd_code.present? && facility.teleconsultation_phone_number.present?
  end

  def set_facility
    @facility ||= Facility.find(params[:facility_id])
  end

  def validate_teleconsultation_facility_belongs_to_users_facility_group
    head :unauthorized unless current_facility_group.facilities.where(id: facility.id).present?
  end
end
