class MyFacilitiesController < AdminController
  include DistrictFiltering
  include Pagination
  include SizeFiltering

  def index
    authorize(:dashboard, :show?)

    @users_requesting_approval = policy_scope([:manage, :user, User])
                                     .requested_sync_approval
                                     .order(updated_at: :desc)

    @users_requesting_approval = paginate(@users_requesting_approval)

    @facilities = policy_scope([:manage, :facility, Facility])
    @inactive_facilities = MyFacilitiesQuery.inactive_facilities(@facilities)


    @facility_count_by_size = { total: @facilities.group(:facility_size).count,
                                inactive: @inactive_facilities.group(:facility_size).count }

    @bp_counts_last_week = @inactive_facilities.bp_counts_in_period(1.week.ago, Time.current)
    @bp_counts_last_month = @inactive_facilities.bp_counts_in_period(1.month.ago, Time.current)
  end

  def ranked_facilities
    authorize(:dashboard, :show?)

    filtered_facilities = facilities_by_size([:manage, :facility])
    @filtered_inactive_facilities = MyFacilitiesQuery.inactive_facilities(filtered_facilities)
  end
end
