class FacilityService
  def initialize(current_admin)
    @current_admin = current_admin
  end

  def facilities_by_district(district)
    if district == "All"
      @current_admin.accessible_facilities(:manage)
    else
      @current_admin.accessible_facilities(:manage).where(district: district)
    end
  end
end