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

    @facility_count_by_size = { total:    @facilities.group(:facility_size).count,
                                inactive: @inactive_facilities.group(:facility_size).count }

    @inactive_facilities_bps = @inactive_facilities.left_outer_joins(:blood_pressures)
    @bp_counts_last_week = @inactive_facilities_bps
                               .where('recorded_at IS NULL OR recorded_at > ?', 1.week.ago)
                               .group('facilities.id')
                               .count(:blood_pressures)
    @bp_counts_last_month = @inactive_facilities_bps
                                .where('recorded_at IS NULL OR recorded_at > ?', 1.month.ago)
                                .group('facilities.id')
                                .count(:blood_pressures)
  end

  def ranked_facilities
    authorize(:dashboard, :show?)
  end
end
