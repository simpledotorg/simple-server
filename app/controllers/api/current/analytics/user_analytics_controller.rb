class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  layout false

  WEEKS_TO_REPORT = 4

  def show
    stats_for_user = new_patients_by_facility_week

    @max_key = stats_for_user.keys.max
    @max_value = stats_for_user.values.max
    @formated_stats = format_stats_for_view(stats_for_user)

    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats_for_user }
    end
  end

  private

  def new_patients_by_facility_week
    PatientsQuery
      .new
      .registered_at(current_facility.id)
      .group_by_week('device_created_at', last: WEEKS_TO_REPORT)
      .count
  end

  def format_stats_for_view(stats)
    stats.map { |k, v| [k, { label: label_for_week(k, v), value: v }] }.to_h
  end

  def label_for_week(week, value)
    return graph_label(value, 'This week', '') if week == @max_value
    start_date = week.at_beginning_of_week
    end_date = week.at_end_of_week
    graph_label(value, start_date.strftime('%b %d'), 'to ' + end_date.strftime('%b %d'))
  end

  def graph_label(value, from_date_string, to_date_string)
    "<div class='graph-label'><p>#{from_date_string}</p><p>#{to_date_string}</p>".html_safe
  end
end
