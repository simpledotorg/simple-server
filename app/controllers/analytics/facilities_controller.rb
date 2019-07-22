class Analytics::FacilitiesController < AnalyticsController
  before_action :set_facility

  def show
  end

  helper_method :analytics
  helper_method :analytics_cache_key

  def analytics
    {
      cohort: @facility.cohort_analytics,
      dashboard: @facility.dashboard_analytics,
    }
  end

  def analytics_cache_key
    today = Date.today.strftime("%Y-%m-%d")
    "analytics/#{today}/facilities/#{@facility.id}"
  end

  def share_anonymized_data
    recipient_email = current_admin.email
    recipient_name = recipient_email.split('@').first

    AnonymizedDataDownloadJob.perform_later(recipient_name,
                                            recipient_email,
                                            { facility_id: @facility.id },
                                            'facility')

    redirect_to analytics_facility_path(id: @facility.id),
                notice: I18n.t('anonymized_data_download_email.facility_notice', facility_name: @facility.name)
  end

  private

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end
end

