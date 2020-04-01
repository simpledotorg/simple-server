class Legacy::UserAnalyticsPresenter < Struct.new(:current_facility)
  include DashboardHelper

  MONTHS_TO_REPORT = 6

  def statistics
    {
      first_of_current_month: first_of_current_month,
      total_patients_count: total_patients_count,
      follow_up_patients_per_month: follow_up_patients_per_month,
      patients_enrolled_per_month: patients_enrolled_per_month
    }
  end

  def first_of_current_month
    Date.current.at_beginning_of_month
  end

  def first_patient_at_facility
    current_facility.registered_patients.order(:recorded_at).first
  end

  def total_patients_count
    Patient.where(registration_facility_id: current_facility.id).count
  end

  def follow_up_patients_per_month
    analytics = FacilityAnalyticsQuery
                  .new(current_facility, :month, MONTHS_TO_REPORT, include_current_period: true)
                  .follow_up_patients_by_period || {}

    dates_for_periods(:month, MONTHS_TO_REPORT, include_current_period: true).map do |date|
      [date, analytics_totals(analytics, :follow_up_patients_by_period, date)]
    end.reverse.to_h
  end

  def patients_enrolled_per_month
    Patient.where(registration_facility_id: current_facility.id)
      .group_by_month(:recorded_at, reverse: true, last: MONTHS_TO_REPORT)
      .count
      .select { |k, _| k >= first_patient_at_facility.recorded_at.at_beginning_of_month }
  end
end
