module OverdueListFiltering
  extend ActiveSupport::Concern

  included do
    before_action :set_accessible_facilities, only: [:index]
    before_action :populate_districts, only: [:index]
    before_action :set_selected_district, only: [:index]
    before_action :populate_facilities, only: [:index]
    before_action :set_selected_facility, only: [:index]

    private

    def set_accessible_facilities
      @accessible_facilities = current_admin.accessible_facilities(:manage_overdue_list)
    end

    def populate_districts
      @districts =
        Region.district_regions.where(source_id: @accessible_facilities.map(&:facility_group_id).uniq).order(:name)
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
