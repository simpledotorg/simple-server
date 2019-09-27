class Analytics::FacilitiesController < AnalyticsController
  include GraphicsDownload
  include QuarterHelper
  include Pagination

  before_action :set_facility

  def show
    set_cohort_analytics(@period, @prev_periods)
    set_dashboard_analytics(@period, 3)

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
    set_cohort_analytics(:quarter, 3)
    set_dashboard_analytics(:quarter, 3)

    whatsapp_graphics_handler(
      @facility.organization.name,
      @facility.name)
  end

  private

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end

  def set_cohort_analytics(period, prev_periods)
    @cohort_analytics = set_analytics_cache(
      analytics_cache_key_cohort(period),
      @facility.cohort_analytics(period, prev_periods)
    )
  end

  def set_dashboard_analytics(period, prev_periods)
    @dashboard_analytics = set_analytics_cache(
      analytics_cache_key_dashboard(period),
      @facility.dashboard_analytics(period: period, prev_periods: prev_periods)
    )
  end

  def analytics_cache_key
    "analytics/facilities/#{@facility.id}"
  end
end

