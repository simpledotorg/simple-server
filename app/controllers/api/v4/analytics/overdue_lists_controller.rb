class Api::V4::Analytics::OverdueListsController < Api::V4::AnalyticsController
  def show
    @patient_summaries = PatientSummaryQuery.call(
      assigned_facility: current_facility,
      next_appointment_facilities: current_facility,
      only_overdue: false
    ).order(risk_level: :desc, next_appointment_scheduled_date: :desc, id: :asc)

    send_data render_to_string("appointments/index.csv.erb"), filename: download_filename
  end

  private

  def download_filename
    "overdue-patients_#{current_facility.name.parameterize}_#{Time.current.to_s(:number)}.csv"
  end
end
