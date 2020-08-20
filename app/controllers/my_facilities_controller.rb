# frozen_string_literal: true

class MyFacilitiesController < AdminController
  include DistrictFiltering
  include Pagination
  include MyFacilitiesFiltering
  include CohortPeriodSelection
  include PeriodSelection

  DEFAULT_ANALYTICS_TIME_ZONE = "Asia/Kolkata"
  PERIODS_TO_DISPLAY = {quarter: 3, month: 3, day: 14}.freeze

  around_action :set_time_zone
  before_action :authorize_my_facilities
  before_action :set_selected_cohort_period, only: [:blood_pressure_control]
  before_action :set_selected_period, only: [:registrations, :missed_visits]

  def index
    @facilities = if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin.accessible_facilities(:view_reports)
    else
      policy_scope([:manage, :facility, Facility])
    end
    @users_requesting_approval = paginate(policy_scope([:manage, :user, User])
                                            .requested_sync_approval
                                            .order(updated_at: :desc))

    overview_query = MyFacilities::OverviewQuery.new(facilities: @facilities)
    @inactive_facilities = overview_query.inactive_facilities

    @facility_counts_by_size = {total: @facilities.group(:facility_size).count,
                                inactive: @inactive_facilities.group(:facility_size).count}

    @inactive_facilities_bp_counts =
      {last_week: overview_query.total_bps_in_last_n_days(n: 7),
       last_month: overview_query.total_bps_in_last_n_days(n: 30)}
  end

  def blood_pressure_control
    @facilities = filter_facilities([:manage, :facility])

    bp_query = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities,
                                                           cohort_period: @selected_cohort_period)

    @totals = {registered: bp_query.cohort_registrations.count,
               controlled: bp_query.cohort_controlled_bps.count,
               uncontrolled: bp_query.cohort_uncontrolled_bps.count,
               missed: bp_query.cohort_missed_visits_count,
               overall_patients: bp_query.overall_patients.count,
               overall_controlled_bps: bp_query.overall_controlled_bps.count}

    @registered_patients_per_facility = bp_query.cohort_registrations.group(:registration_facility_id).count
    @controlled_bps_per_facility = bp_query.cohort_controlled_bps.group(:registration_facility_id).count
    @uncontrolled_bps_per_facility = bp_query.cohort_uncontrolled_bps.group(:registration_facility_id).count
    @missed_visits_by_facility = bp_query.cohort_missed_visits_count_by_facility
    @overall_patients_per_facility = bp_query.overall_patients.group(:registration_facility_id).count
    @overall_controlled_bps_per_facility = bp_query.overall_controlled_bps.group(:registration_facility_id).count
  end

  def registrations
    @facilities = filter_facilities([:manage, :facility])

    registrations_query = MyFacilities::RegistrationsQuery.new(facilities: @facilities,
                                                               period: @selected_period,
                                                               last_n: PERIODS_TO_DISPLAY[@selected_period])

    @registrations = registrations_query.registrations
      .group(:facility_id, :year, @selected_period)
      .sum(:registration_count)

    @total_registrations = registrations_query.total_registrations.group(:registration_facility_id).count
    @total_registrations_by_period =
      @registrations.each_with_object({}) { |(key, registrations), total_registrations_by_period|
        period = [key.second.to_i, key.third.to_i]
        total_registrations_by_period[period] ||= 0
        total_registrations_by_period[period] += registrations
      }
    @display_periods = registrations_query.periods
  end

  def missed_visits
    @facilities = filter_facilities([:manage, :facility])

    missed_visits_query = MyFacilities::MissedVisitsQuery.new(facilities: @facilities,
                                                              period: @selected_period,
                                                              last_n: PERIODS_TO_DISPLAY[@selected_period])

    @display_periods = missed_visits_query.periods
    @missed_visits_by_facility = missed_visits_query.missed_visits_by_facility
    @calls_made = missed_visits_query.calls_made.count
    @total_registrations = missed_visits_query.total_registrations
    @totals_by_period = missed_visits_query.missed_visit_totals
  end

  private

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Time.use_zone(time_zone) { yield }
  end

  def authorize_my_facilities
    if Flipper.enabled?(:new_permissions_system_aug_2020, current_admin)
      current_admin.authorize(:view_reports, :facility)
    else
      authorize(:dashboard, :view_my_facilities?)
    end
  end
end
