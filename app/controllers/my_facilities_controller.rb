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

    @bp_counts_last_week = @inactive_facilities.bp_counts_in_period(1.week.ago, Time.current)
    @bp_counts_last_month = @inactive_facilities.bp_counts_in_period(1.month.ago, Time.current)
  end

  def ranked_facilities
    authorize(:dashboard, :show?)
  end
end
