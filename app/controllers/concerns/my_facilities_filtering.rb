# frozen_string_literal: true

module MyFacilitiesFiltering
  extend ActiveSupport::Concern

  included do
    before_action :populate_facilities
    before_action :populate_facility_groups
    before_action :set_selected_facility_group
    before_action :populate_facility_sizes
    before_action :populate_zones
    before_action :set_selected_facility_sizes
    before_action :set_selected_zones

    def filter_facilities
      filtered_facilities = facilities_by_facility_group(@facilities)
      filtered_facilities = facilities_by_size(filtered_facilities)
      facilities_by_zone(filtered_facilities)
    end

    private

    def populate_facilities
      @facilities = current_admin.accessible_facilities(:view_reports)
    end

    def populate_facility_groups
      @facility_groups = FacilityGroup.where(id: @facilities.map(&:facility_group_id).uniq).order(:name)
    end

    def populate_facility_sizes
      @facility_sizes = Facility.facility_sizes.keys.reverse
    end

    def populate_zones
      @zones = @facilities.pluck(:zone).uniq.compact.sort
    end

    def set_selected_facility_group
      @selected_facility_group = params[:facility_group] ? @facility_groups.find_by(slug: params[:facility_group]) : @facility_groups.first
    end

    def set_selected_facility_sizes
      @selected_sizes = params[:size].present? ? [params[:size]] : @facility_sizes
    end

    def set_selected_zones
      @selected_zones = params[:zone].present? ? [params[:zone]] : @zones
    end

    def facilities_by_facility_group(facilities)
      facilities.where(facility_group: @selected_facility_group)
    end

    def facilities_by_size(facilities)
      if (@facility_sizes - @selected_sizes).empty?
        facilities
      else
        facilities.where(facility_size: @selected_sizes)
      end
    end

    def facilities_by_zone(facilities)
      facilities.where(zone: @selected_zones).or(facilities.where(zone: nil))
    end
  end
end
