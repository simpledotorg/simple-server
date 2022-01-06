# frozen_string_literal: true

module OverdueListFiltering
  extend ActiveSupport::Concern

  included do
    private

    def filter_district_and_facilities
      set_accessible_facilities
      populate_districts
      set_selected_district
      populate_facilities
      set_selected_facility
    end

    def set_accessible_facilities
      @accessible_facilities = current_admin.accessible_facilities(:manage_overdue_list)
    end

    def populate_districts
      @districts =
        Region.district_regions
          .joins("INNER JOIN regions facility_region ON regions.path @> facility_region.path")
          .where("facility_region.source_id" => @accessible_facilities.map(&:id))
          .distinct(:slug)
          .order(:name)
    end

    def set_selected_district
      @selected_district =
        if params[:district_slug]
          @districts.find_by(slug: params[:district_slug])
        elsif @districts.present?
          @districts.first
        end
    end

    def populate_facilities
      @facilities = @accessible_facilities.where(id: @selected_district&.facilities)
    end

    def set_selected_facility
      @selected_facility = @facilities.find_by(id: params[:facility_id]) if params[:facility_id].present?
    end
  end
end
