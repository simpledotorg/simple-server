module FacilityFiltering
  extend ActiveSupport::Concern

  included do
    before_action :set_facility_id, only: [:index]

    helper_method :current_facility

    private

    def set_facility_id
      @facility_id = params[:facility_id].present? ? params[:facility_id] : 'All'
    end

    def current_facility
      @facility_id == 'All' ? nil : Facility.find(@facility_id)
    end
  end
end
