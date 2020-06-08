class Analytics::DistrictsController < AnalyticsController
  include QuarterHelper
  include GraphicsDownload

  before_action :set_organization_district
  skip_after_action :verify_authorized

  def show
    @show_current_period = true

    set_dashboard_analytics(@period, 6)
    set_cohort_analytics(@period, @prev_periods)

    respond_to do |format|
      format.html
      format.csv do
        set_facility_keys
        send_data render_to_string('show.csv.erb'), filename: download_filename
      end
    end
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
      notice: I18n.t('patient_list_email.notice',
                     model_type: "district",
                     model_name: @organization_district.district_name))
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
  end

  def set_cohort_analytics(period, prev_periods)
    @cohort_analytics =
      set_analytics_cache(analytics_cache_key_cohort(period)) do
        @organization_district.cohort_analytics(period, prev_periods)
      end
  end

  def set_dashboard_analytics(period, prev_periods)
    @dashboard_analytics =
      set_analytics_cache(analytics_cache_key_dashboard(period)) do
        @organization_district.dashboard_analytics(period: period,
                                                   prev_periods: prev_periods,
                                                   include_current_period: @show_current_period)
      end
  end

  def set_facility_keys
    district = {
      id: :total,
      name: "Total",
      type: "District"
    }.with_indifferent_access

    facilities = @organization_district.facilities.order(:name).map { |facility|
      {
        id: facility.id,
        name: facility.name,
        facility_type: facility.facility_type
      }.with_indifferent_access
    }

    @facility_keys = [district, *facilities]
  end

  def analytics_cache_key
    sanitized_district_name = @organization_district.district_name.downcase.split(' ').join('-')
    "analytics/organization/#{@organization_district.organization.id}/district/#{sanitized_district_name}"
  end

  def download_filename
    period = @period == :quarter ? "quarterly" : "monthly"
    district = @organization_district.district_name
    time = Time.current.to_s(:number)
    "district-#{period}-cohort-report_#{district}_#{time}.csv"
  end
end
