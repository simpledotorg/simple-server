class Analytics::FacilitiesController < AnalyticsController
  include GraphicsDownload
  include QuarterHelper
  include Pagination

  before_action :set_facility
  before_action :set_cohort_analytics, only: [:show, :whatsapp_graphics]

  def show
    set_dashboard_analytics(:month)

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
    set_dashboard_analytics(:month)

    whatsapp_graphics_handler(
      @facility.organization.name,
      @facility.name)
  end

  private

  def set_cohort_analytics
    @cohort_analytics = Rails.cache.fetch(analytics_cache_key_cohort) { @facility.cohort_analytics }
  end

  def set_dashboard_analytics(time_period)
    @dashboard_analytics = Rails.cache.fetch(analytics_cache_key_dashboard(time_period)) {
      @facility.dashboard_analytics(time_period: time_period)
    }
  end

  def analytics_cache_key
    "analytics/facilities/#{@facility.id}"
  end

  def analytics_cache_key_cohort
    "#{analytics_cache_key}/cohort"
  end

  def analytics_cache_key_dashboard(time_period)
    "#{analytics_cache_key}/dashboard/#{time_period}"
  end

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end
end

