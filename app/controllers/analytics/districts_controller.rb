class Analytics::DistrictsController < AnalyticsController
  include GraphicsDownload
  include QuarterHelper

  before_action :set_organization_district
  # before_action :set_analytics, only: [:show, :whatsapp_graphics]

  def show
    cohort_analytics = Rails.cache.fetch(analytics_cache_key_cohort) {
      @organization_district.cohort_analytics
    }

    dashboard_analytics = Rails.cache.fetch(analytics_cache_key_dashboard(:month)) {
      @organization_district.dashboard_analytics(time_period: :month)
    }

    @analytics = {
      cohort: cohort_analytics,
      dashboard: dashboard_analytics
    }
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
    cohort_analytics = Rails.cache.fetch(analytics_cache_key_cohort) {
      @organization_district.cohort_analytics
    }

    dashboard_analytics = Rails.cache.fetch(analytics_cache_key_dashboard(:quarter)) {
      @organization_district.dashboard_analytics(time_period: :quarter)
    }

    @analytics = {
      cohort: cohort_analytics,
      dashboard: dashboard_analytics
    }

    whatsapp_graphics_handler(
      @organization_district.organization.name,
      @organization_district.district_name)
  end

  private

  def analytics_cache_key_cohort
    sanitized_district_name = @organization_district.district_name.downcase.split(' ').join('-')
    "analytics/organization/#{@organization_district.organization.id}/district/#{sanitized_district_name}/cohort"
  end

  def analytics_cache_key_dashboard(time_period)
    sanitized_district_name = @organization_district.district_name.downcase.split(' ').join('-')
    "analytics/organization/#{@organization_district.organization.id}/district/#{sanitized_district_name}/dashboard/#{time_period}"
  end

  def set_organization_district
    district_name = params[:id] || params[:district_id]
    organization = Organization.find_by(id: params[:organization_id])
    @organization_district = OrganizationDistrict.new(district_name, organization)
    authorize(@organization_district)
  end
end
