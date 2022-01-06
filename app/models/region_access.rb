# frozen_string_literal: true

class RegionAccess
  include Memery
  attr_reader :user_access
  attr_reader :user

  def initialize(user, memoized: false)
    @user_access = user.user_access
    @user = user
    @memoized = memoized
  end

  def accessible_region?(region, action)
    public_send("accessible_#{region.region_type}?", region, action)
  end

  # An admin can view a state if they have view_reports access to any of the state's districts
  def accessible_state?(region, action)
    return true if user.power_user?
    accessible_region_ids(region.region_type, action).include?(region.id)
  end

  def accessible_district?(region, action)
    return true if user.power_user?
    accessible_region_ids(region.region_type, action).include?(region.id)
  end

  def accessible_block?(region, action)
    return true if user.power_user?
    accessible_region_ids(region.region_type, action).include?(region.id)
  end

  private

  def accessible_region_ids(region_type, action)
    meth = "accessible_#{region_type}_regions"
    user_access.public_send(meth, action).pluck(:id)
  end

  memoize :accessible_region_ids, condition: -> { memoized? }

  def memoized?
    @memoized == true
  end
end
