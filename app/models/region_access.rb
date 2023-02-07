class RegionAccess
  include Memery
  attr_reader :user_access
  attr_reader :user

  def initialize(user, memoized: false)
    @user_access = user.user_access
    @user = user
    @memoized = memoized
  end

  # An admin can view a state if they have view_reports access to any of the state's districts
  def accessible_region?(region, action)
    return true if user.power_user?
    accessible_region_ids(region.region_type, action).include?(region.id)
  end

  alias_method :accessible_state?, :accessible_region?
  alias_method :accessible_district?, :accessible_region?
  alias_method :accessible_block?, :accessible_region?

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
