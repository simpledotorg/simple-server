class RegionAccess
  attr_reader :user
  def initialize(user)
    @user = user
  end

  def accessible_region?(region)
    public_send "accessible_#{region.region_type}?", region
  end

  # An admin can view a state if they have view_reports access to any of the state's districts
  def accessible_state?(region)
    return true if user.power_user?
    @accessible_state_ids ||= user.user_access.accessible_state_regions(:view_reports).pluck(:id)
    @accessible_state_ids.include?(region.id)
  end

  def accessible_district?(region)
    return true if user.power_user?
    @accessible_district_ids ||= user.accessible_district_regions(:view_reports).pluck(:id)
    @accessible_district_ids.include?(region.id)
  end

  def accessible_block?(region)
    return true if user.power_user?
    @accessible_block_ids ||= user.accessible_block_regions(:view_reports).pluck(:id)
    @accessible_block_ids.include?(region.id)
  end
end