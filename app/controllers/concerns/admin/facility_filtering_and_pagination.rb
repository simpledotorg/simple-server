module Admin::FacilityFilteringAndPagination
  DEFAULT_PAGE_SIZE = 20

  extend ActiveSupport::Concern
  included do
    before_action :set_facility_id, only: [:index]
    before_action :set_per_page, only: [:index]

    def selected_facilities
      if @facility_id == 'All'
        policy_scope(Facility.all)
      else
        policy_scope(Facility.where(id: @facility_id))
      end
    end

    def paginate(records_to_show)
      if @per_page == 'All'
        records_to_show.size
      else
        @per_page.to_i
      end
    end

    private

    def set_facility_id
      @facility_id = params[:facility_id].present? ? params[:facility_id] : 'All'
    end

    def set_per_page
      @per_page = params[:per_page] || DEFAULT_PAGE_SIZE
    end
  end
end
