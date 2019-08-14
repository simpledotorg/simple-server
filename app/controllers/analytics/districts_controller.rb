class Analytics::DistrictsController < AnalyticsController
  include QuarterHelper
  include GraphicsDownload

  before_action :set_organization_district
  before_action :set_cohort_analytics, only: [:show, :whatsapp_graphics]

  def show
    set_dashboard_analytics(:month)
  end

  def share_anonymized_data
    recipient_email = current_admin.email
    recipient_name = recipient_email.split('@').first

    AnonymizedDataDownloadJob.perform_later(recipient_name,
                                            recipient_email,
                                            { district_name: @organization_district.district_name,
                                              organization_id: @organization_district.organization.id },
                                            'district')

    redirect_to analytics_organization_district_path(id: @organization_district.district_name),
                notice: I18n.t('anonymized_data_download_email.district_notice',
                               district_name: @organization_district.district_name)
  end

  def whatsapp_graphics
    set_dashboard_analytics(:quarter)

    whatsapp_graphics_handler(
      @organization_district.organization.name,
      @organization_district.district_name)
  end

  private

  def set_cohort_analytics
    @cohort_analytics = set_analytics_cache(analytics_cache_key_cohort,
                                            @organization_district.cohort_analytics)
  end

  def set_dashboard_analytics(time_period)
    @dashboard_analytics = set_analytics_cache(analytics_cache_key_dashboard(time_period),
                                               @organization_district.dashboard_analytics(time_period: time_period))
  end

  def analytics_cache_key
    sanitized_district_name = @organization_district.district_name.downcase.split(' ').join('-')
    "analytics/organization/#{@organization_district.organization.id}/district/#{sanitized_district_name}"
  end

  def set_organization_district
    district_name = params[:id] || params[:district_id]
    organization = Organization.find_by(id: params[:organization_id])
    @organization_district = OrganizationDistrict.new(district_name, organization)
    authorize(@organization_district)
  end
end
