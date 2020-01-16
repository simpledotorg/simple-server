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

  def blood_pressure_control
    @facilities = policy_scope([:manage, :facility, Facility])

    registered_patients = MyFacilitiesQuery.cohort_registrations(@facilities)
    controlled_bps = MyFacilitiesQuery.cohort_controlled_bps(@facilities)
    uncontrolled_bps = MyFacilitiesQuery.cohort_uncontrolled_bps(@facilities)

    @totals = { registered: registered_patients.count,
                controlled: controlled_bps.count,
                uncontrolled: uncontrolled_bps.count }

    registered_patients_per_facility = registered_patients.group(:registration_facility_id).count
    controlled_bps_per_facility = controlled_bps.group(:facility_id).count
    uncontrolled_bps_per_facility = uncontrolled_bps.group(:facility_id).count

    @bp_control_by_facility = @facilities.map do |f|
      [f.id, { registered: registered_patients_per_facility[f.id] || 0,
               controlled: controlled_bps_per_facility[f.id] || 0,
               uncontrolled: uncontrolled_bps_per_facility[f.id] || 0 }]
    end.to_h
  end

  private

  def authorize_my_facilities
    authorize(:dashboard, :show?)
  end
end
