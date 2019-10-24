class Analytics::DistrictsController < AnalyticsController
  include QuarterHelper
  include GraphicsDownload

  before_action :set_organization_district

  def show
    set_cohort_analytics(@period, @prev_periods)
    set_dashboard_analytics(@period, 3)
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

  def patient_list
    recipient_email = current_admin.email

    PatientListDownloadJob.perform_later(recipient_email, 'district', {
      district_name: @organization_district.district_name,
      organization_id: @organization_district.organization.id
    })

    redirect_to(
      analytics_organization_district_path(id: @organization_district.district_name),
      notice: I18n.t('patient_list_email.notice', model_type: "district", model_name: @organization_district.district_name)
    )
  end

  def whatsapp_graphics
    set_cohort_analytics(:quarter, 3)
    set_dashboard_analytics(:quarter, 4)

    whatsapp_graphics_handler(
      @organization_district.organization.name,
      @organization_district.district_name)
  end

  private

  def set_organization_district
    district_name = params[:id] || params[:district_id]
    organization = Organization.find_by(id: params[:organization_id])
    @organization_district = OrganizationDistrict.new(district_name, organization)
    authorize([:cohort_report, @organization_district])
  end

  def set_cohort_analytics(period, prev_periods)
    @cohort_analytics = set_analytics_cache(
      analytics_cache_key_cohort(period),
      @organization_district.cohort_analytics(period, prev_periods)
    )
  end

  def set_dashboard_analytics(period, prev_periods)
    @dashboard_analytics = set_analytics_cache(
      analytics_cache_key_dashboard(period),
      @organization_district.dashboard_analytics(period: period, prev_periods: prev_periods)
    )
  end

  def analytics_cache_key
    sanitized_district_name = @organization_district.district_name.downcase.split(' ').join('-')
    "analytics/organization/#{@organization_district.organization.id}/district/#{sanitized_district_name}"
  end
end
