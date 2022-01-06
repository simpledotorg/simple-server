# frozen_string_literal: true

class Api::V4::FacilityTeleconsultationsController < APIController
  before_action :set_facility
  before_action :validate_teleconsultation_facility_belongs_to_users_facility_group

  attr_reader :facility

  def show
    render json: {
      teleconsultation_phone_number: facility.teleconsultation_phone_number_with_isd,
      teleconsultation_phone_numbers: facility.teleconsultation_phone_numbers_with_isd.map { |number|
        {phone_number: number}
      }
    }
  end

  private

  def set_facility
    @facility ||= Facility.find(params[:facility_id])
  end

  def validate_teleconsultation_facility_belongs_to_users_facility_group
    head :unauthorized unless current_facility_group.facilities.where(id: facility.id).present?
  end
end
