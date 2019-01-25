class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  layout false

  WEEKS_TO_REPORT = 4

  def show
    @stats_for_user = new_patients_by_facility_week
    @application_js = asset_source('application.js')

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

  def asset_source(asset_path)
    asset = Rails.application.assets.find_asset(asset_path)
    if Rails.application.config.assets.compile
      asset.source
    else
      File.read(File.join(Rails.root, 'public', 'assets', asset.digest_path))
    end
  end
end