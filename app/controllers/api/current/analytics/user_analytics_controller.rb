class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  layout false

  MONTHS_TO_REPORT = 6

  def show
    Timecop.travel(2.months.ago) do
      @statistics = nil

      unless first_patient_at_facility.present?
        return respond_to_html_or_json(nil)
      end

      @statistics = {
        first_of_current_month: first_of_current_month,
        total_patients_count: total_patients_count,
        unique_patients_per_month: unique_patients_recorded_per_month,
        patients_enrolled_per_month: patients_enrolled_per_month
      }

      respond_to_html_or_json(@statistics)
    end
  end

  private

  def respond_to_html_or_json(stats)
    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats }
    end
  end

  def first_of_current_month
    Date.today.at_beginning_of_month
  end

  def first_patient_at_facility
    current_facility.registered_patients.order(:device_created_at).first
  end

  def total_patients_count
    Patient.where(registration_facility_id: current_facility.id).count
  end

  def unique_patients_recorded_per_month
    BloodPressure.where(facility: current_facility)
      .group_by_month(:device_created_at, last: MONTHS_TO_REPORT, reverse: true)
      .count('distinct patient_id')
      .select { |k, v| k >= first_patient_at_facility.device_created_at.at_beginning_of_month }
  end

  def patients_enrolled_per_month
    Patient.where(registration_facility_id: current_facility.id)
      .group_by_month(:device_created_at, reverse: true, last: MONTHS_TO_REPORT)
      .count
  end
end
