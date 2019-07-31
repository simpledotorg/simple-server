class Analytics::DistrictsController < AnalyticsController
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
        render_graphics_image(
          @organization_district.organization.name,
          @organization_district.district_name)
      end
      format.html { render }
    end
  end

  private

  def render_graphics_image(organization_name, district_name)
    kit = IMGKit.new(
      render_to_string('/analytics/districts/graphics/image_template', formats: [:html], layout: false),
      width: 0, height: 0, enable_smart_width: true, transparent: true
    )

    send_data(
      kit.to_png, type: "image/png",
      filename: "whatsapp_graphics_#{organization_name}_#{district_name}_#{Date.today}.png"
    )
  end

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