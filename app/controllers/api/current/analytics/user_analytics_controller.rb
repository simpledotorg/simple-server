class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  layout false

  MONTHS_TO_REPORT = 6

  def show
    @stats_for_user = new_patients_by_facility_month

    @start_of_current_week = helpers.start_of_week(Date.today)
    @max_value = @stats_for_user.present? ? @stats_for_user.values.max : nil
    @formatted_stats = format_stats_for_view(@stats_for_user)
    @total_patients_count = total_patients_count
    @patients_enrolled_per_month = patients_enrolled_per_month

    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats_for_user }
    end
  end

  private

  def new_patients_by_facility_month
    first_patient_at_facility = current_facility.patients.order(:device_created_at).first
    return unless first_patient_at_facility.present?
    Patient.where(registration_facility_id: current_facility.id)
      .group_by_month('device_created_at', last: MONTHS_TO_REPORT)
      .count
      .select { |k, v| k >= first_patient_at_facility.device_created_at.at_beginning_of_month }
  end

  def total_patients_count
    PatientsQuery.new
      .registered_at(current_facility.id)
      .count
  end

  def patients_enrolled_per_month
    PatientsQuery.new
      .registered_at(current_facility.id)
      .group_by_month(:device_created_at, reverse: true, last: MONTHS_TO_REPORT)
      .count
  end

  def format_stats_for_view(stats)
    stats.map { |k, v| [k, { label: helpers.label_for_week(k, v), value: v }] }.to_h
  end
end
