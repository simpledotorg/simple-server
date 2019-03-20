class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  layout false

  WEEKS_TO_REPORT = 4

  def show
    stats_for_user = new_patients_by_facility_week

    @max_key = stats_for_user.keys.max
    @max_value = stats_for_user.values.max
    @formatted_stats = format_stats_for_view(stats_for_user)
    @total_patients_count = total_patients_count
    @patients_enrolled_per_month = patients_enrolled_per_month

    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats_for_user }
    end
  end

  private

  def new_patients_by_facility_week
    first_patient_at_facility = current_facility.patients.order(:device_created_at).first
    Patient.where(registration_facility_id: current_facility.id)
      .group_by_week('device_created_at', last: WEEKS_TO_REPORT)
      .count
      .select { |k, v| k >= first_patient_at_facility.device_created_at.at_beginning_of_week(start_day = :sunday) }
  end

  def total_patients_count
    PatientsQuery.new
      .registered_at(current_facility.id)
      .count
  end

  def patients_enrolled_per_month
    PatientsQuery.new
      .registered_at(current_facility.id)
      .group_by_month(:device_created_at, reverse: true)
      .count
  end

  def format_stats_for_view(stats)
    stats.map { |k, v| [k, { label: label_for_week(k, v), value: v }] }.to_h
  end

  def label_for_week(week, value)
    return graph_label(value, 'This week', '') if week == Date.today.at_beginning_of_week(start_day = :sunday)
    start_date = week.at_beginning_of_week(start_day = :sunday)
    end_date = start_date.at_end_of_week(start_day = :sunday)
    graph_label(value, start_date.strftime('%b %e'), 'to ' + end_date.strftime('%b %e'))
  end

  def graph_label(value, from_date_string, to_date_string)
    "<div class='graph-label'><div class='label-1'>#{from_date_string}</div><div class='label-2'>#{to_date_string}</div>".html_safe
  end
end
