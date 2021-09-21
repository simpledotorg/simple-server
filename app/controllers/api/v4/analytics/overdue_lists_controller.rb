class Api::V4::Analytics::OverdueListsController < Api::V4::AnalyticsController
  def show
    respond_to do |format|
      format.csv do
        @patient_summaries =
          PatientSummaryQuery.call(assigned_facilities: [current_facility], only_overdue: false)
            .includes(:latest_bp_passport, :current_prescription_drugs)
            .order(risk_level: :desc, next_appointment_scheduled_date: :desc, id: :asc)

        send_data render_to_string("show.csv.erb"), filename: download_filename
      end
    end
  end

  private

  def download_filename
    "overdue-patients_#{current_facility.name.parameterize}_#{Time.current.strftime("%d-%b-%Y-%H%M%S")}.csv"
  end
end
