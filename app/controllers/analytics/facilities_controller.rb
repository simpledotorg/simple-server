class Analytics::FacilitiesController < AnalyticsController
  include GraphicsDownload
  include QuarterHelper
  include Pagination

  before_action :set_facility
  before_action :set_analytics, only: [:show, :whatsapp_graphics]

  def show
    @recent_blood_pressures = @facility.blood_pressures
                                .includes(:patient, :user)
                                .order("DATE(recorded_at) DESC, recorded_at ASC")

    @recent_blood_pressures = paginate(@recent_blood_pressures)
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

  def whatsapp_graphics
    @cohort_analytics = @facility.cohort_analytics
    @dashboard_analytics = @facility.dashboard_analytics(time_period: 'quarter')

    whatsapp_graphics_handler(
      @facility.organization.name,
      @facility.name)
  end

  private

  def set_analytics
    if FeatureToggle.enabled?('CACHED_QUERIES_FOR_DASHBOARD')
      @analytics = Rails.cache.fetch(analytics_cache_key) { analytics }
    else
      @analytics = analytics
    end
  end

  def analytics
    {
      cohort: @facility.cohort_analytics,
      dashboard: @facility.dashboard_analytics,
    }
  end

  # invalidate analytics cache after 1 day
  def analytics_cache_key
    today = Date.today.strftime("%Y-%m-%d")
    "analytics/#{today}/facilities/#{@facility.id}"
  end

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end
end

