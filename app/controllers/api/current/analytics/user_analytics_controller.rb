class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  layout false

  WEEKS_TO_REPORT = 4

  def show
    @stats_for_user = new_patients_by_facility_week

    @chartkick_js = read_js_lib('chartkick.min.js')
    @chart_bundle_js = read_js_lib('Chart.bundle.min.js')

    respond_to do |format|
      format.html { render :show }
      format.json { render json: @stats_for_user }
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

  def read_js_lib(file_name)
    File.read(File.join(Rails.root, 'vendor', 'assets', 'javascripts', file_name))
  end
end