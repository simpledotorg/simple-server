module DistrictFiltering
  extend ActiveSupport::Concern

  included do
    before_action :set_district, only: [:index]

    private

    def set_district
      @district = params[:district].present? ? params[:district] : 'All'
    end

    def selected_district_facilities(scope_namespace = [])
      if @district == 'All'
        policy_scope(scope_namespace.concat([Facility.all]))
      else
        policy_scope(scope_namespace.concat([Facility.where(district: @district)]))
      end
    end
  end
end