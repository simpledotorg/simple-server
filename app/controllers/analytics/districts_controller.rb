class Analytics::DistrictsController < AnalyticsController
  include GraphicsDownload

  before_action :set_organization_district
  before_action :set_analytics, only: [:show, :whatsapp_graphics]

  def show
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
    respond_to do |format|
      format.png do
        filename = graphics_filename(
          @organization_district.organization.name,
          @organization_district.district_name,
          Date.today)

        render_as_png('/analytics/districts/graphics/image_template', filename)
      end
      format.html { render }
    end
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
      cohort: @organization_district.cohort_analytics,
      dashboard: @organization_district.dashboard_analytics
    }
  end

  # invalidate analytics cache after 1 day
  def analytics_cache_key
    today = Date.today.strftime("%Y-%m-%d")
    sanitized_district_name = @organization_district.district_name.downcase.split(' ').join('-')
    "analytics/#{today}/organization/#{@organization_district.organization.id}/district/#{sanitized_district_name}"
  end

  def set_organization_district
    district_name = params[:id] || params[:district_id]
    organization = Organization.find_by(id: params[:organization_id])
    @organization_district = OrganizationDistrict.new(district_name, organization)
    authorize(@organization_district)
  end
end