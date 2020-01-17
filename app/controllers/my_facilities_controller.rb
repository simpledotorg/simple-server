# frozen_string_literal: true

class MyFacilitiesController < AdminController
  include DistrictFiltering
  include Pagination
  include FacilitySizeFiltering
  include CohortPeriodSelection

  before_action :authorize_my_facilities

  def index
    @users_requesting_approval = paginate(policy_scope([:manage, :user, User])
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

    @facilities = policy_scope([:manage, :facility, Facility])
    @inactive_facilities = MyFacilitiesQuery.new.inactive_facilities(@facilities)

    @facility_counts_by_size = { total: @facilities.group(:facility_size).count,
                                 inactive: @inactive_facilities.group(:facility_size).count }

    @inactive_facilities_bp_counts =
      { last_week: @inactive_facilities.bp_counts_in_period(start: 1.week.ago, finish: Time.current),
        last_month: @inactive_facilities.bp_counts_in_period(start: 1.month.ago, finish: Time.current) }
  end

  def ranked_facilities; end

  def blood_pressure_control
    @facilities = facilities_by_size([:manage, :facility])

    registered_patients = MyFacilitiesQuery.new(selected_cohort_period).cohort_registrations(@facilities)
    controlled_bps = MyFacilitiesQuery.new(selected_cohort_period).cohort_controlled_bps(@facilities)
    uncontrolled_bps = MyFacilitiesQuery.new(selected_cohort_period).cohort_uncontrolled_bps(@facilities)

    @totals = { registered: registered_patients.count,
                controlled: controlled_bps.count,
                uncontrolled: uncontrolled_bps.count,
                missed: missed_visits(registered_patients.count, controlled_bps.count, uncontrolled_bps.count) }

    @registered_patients_per_facility = registered_patients.group(:registration_facility_id).count
    @controlled_bps_per_facility = controlled_bps.group(:facility_id).count
    @uncontrolled_bps_per_facility = uncontrolled_bps.group(:facility_id).count
    @missed_visits_by_facility = @facilities.map do |f|
      [f.id, missed_visits(@registered_patients_per_facility[f.id].to_i,
                           @controlled_bps_per_facility[f.id].to_i,
                           @uncontrolled_bps_per_facility[f.id].to_i)]
    end.to_h
  end

  private

  def authorize_my_facilities
    authorize(:dashboard, :show?)
  end

  def missed_visits(registered_patients, controlled_bps, uncontrolled_bps)
    registered_patients - controlled_bps - uncontrolled_bps
  end
end
