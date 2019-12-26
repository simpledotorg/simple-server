class MyFacilitiesController < AdminController
  include Pagination

  def index
    authorize(:dashboard, :show?)

    @users_requesting_approval = policy_scope([:manage, :user, User])
                                   .requested_sync_approval
                                   .order(updated_at: :desc)

    @users_requesting_approval = paginate(@users_requesting_approval)

    @facilities = policy_scope([:manage, :facility, Facility])
    @inactive_facilities = @facilities.inactive

    @facility_count_by_size = { total: @facilities.group(:facility_size).count,
                                inactive: @inactive_facilities.group(:facility_size).count }

    @recent_bps_for_inactive_facilities = BloodPressure.with_encounters.where(facility: @inactive_facilities).where('recorded_at > ?', 1.month.ago)
    @bp_count_last_week = @recent_bps_for_inactive_facilities.where('recorded_at > ?', 1.week.ago).group(:facility_id).count
    @bp_count_last_month = @recent_bps_for_inactive_facilities.group(:facility_id).count
  end

  def ranked_facilities
    authorize(:dashboard, :show?)
  end
end
