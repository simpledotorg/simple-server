class CounsellorController < AdminController
  DEFAULT_PAGE_SIZE = 20

  def selected_facilities
    @facility_id = params[:facility_id].present? ? params[:facility_id] : 'All'
    if @facility_id == 'All'
      policy_scope(Facility.all)
    else
      policy_scope(Facility.where(id: @facility_id))
    end
  end

  def paginate(records_to_show)
    @per_page = params[:per_page] || DEFAULT_PAGE_SIZE
    if @per_page == 'All'
      records_to_show.size
    else
      @per_page.to_i
    end
  end
end
