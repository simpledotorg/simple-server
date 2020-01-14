# frozen_string_literal: true

class MyFacilitiesController < AdminController
  include DistrictFiltering
  include Pagination
  include FacilitySizeFiltering

  before_action :authorize_my_facilities

  def index
    @users_requesting_approval = paginate(policy_scope([:manage, :user, User])
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

    @facilities = policy_scope([:manage, :facility, Facility])
    @inactive_facilities = MyFacilitiesQuery.inactive_facilities(@facilities)

    @facility_counts_by_size = { total: @facilities.group(:facility_size).count,
                                 inactive: @inactive_facilities.group(:facility_size).count }

    @inactive_facilities_bp_counts =
      { last_week: @inactive_facilities.bp_counts_in_period(start: 1.week.ago, finish: Time.current),
        last_month: @inactive_facilities.bp_counts_in_period(start: 1.month.ago, finish: Time.current) }
  end

  def ranked_facilities; end

  def blood_pressure_control; end

  private

  def authorize_my_facilities
    authorize(:dashboard, :show?)
  end
end
