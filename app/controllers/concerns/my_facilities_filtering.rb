# frozen_string_literal: true

module MyFacilitiesFiltering
  extend ActiveSupport::Concern
  NEW_FACILITY_THRESHOLD = 3.months.ago

  included do
    before_action :populate_facility_sizes, :populate_zones,
                  :set_selected_sizes, :set_selected_zones, :set_only_new_facilities

    def filter_facilities(scope_namespace = [])
      facilities = policy_scope(scope_namespace.concat([Facility]))
      filtered_facilities = facilities_by_size(facilities)
      facilities_by_zone(filtered_facilities)
    end

    private

    def populate_facility_sizes
      @facility_sizes = Facility.facility_sizes.keys.reverse
    end

    def populate_zones
      @zones = policy_scope([:manage, :facility, Facility]).pluck(:zone).uniq.compact.sort
    end

    def set_selected_sizes
      @selected_sizes = params[:size].present? ? params[:size] : @facility_sizes
    end

    def set_selected_zones
      @selected_zones = params[:zone].present? ? params[:zone] : @zones
    end

    def set_only_new_facilities
      @only_new_facilities = params[:only_new_facilities] ? params[:only_new_facilities] : false
    end

    def facilities_by_size(facilities)
      facilities.where(facility_size: @selected_sizes)
    end

    def facilities_by_zone(facilities)
      facilities.where('zone = ? OR zone IS NULL', @selected_zones)
    end

    def facilities_by_created_at(facilities)
      @only_new_facilities ? facilities.where('created_at > ? ', NEW_FACILITY_THRESHOLD) : facilities
    end
  end
end
