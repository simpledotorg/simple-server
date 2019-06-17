class Analytics::FacilitiesController < AnalyticsController
  before_action :set_facility
  before_action :set_organization
  before_action :set_organization_district

  def show
    @facility_analytics = @facility.patient_set_analytics(@from_time, @to_time)
    @user_analytics = user_analytics
  end

  def share_anonymized_data
    recipient_role = current_admin.role
    recipient_email = current_admin.email
    recipient_name = recipient_email.split('@').first

    AnonymizedDataDownloadJob.perform_later(recipient_name,
                                            recipient_email,
                                            recipient_role,
                                            { facility_id: @facility },
                                            'facility')

    from_time = @from_time.strftime('%Y-%m-%d')
    to_time = @to_time.strftime('%Y-%m-%d')

    redirect_to analytics_facility_path(id: @facility.id, from_time: from_time, to_time: to_time),
                notice: I18n.t('anonymized_data_download_email.facility_notice', facility_name: @facility.name)
  end

  private

  def set_facility
    facility_id = params[:id] || params[:facility_id]
    @facility = Facility.friendly.find(facility_id)
    authorize(@facility)
  end

  def set_organization_district
    @organization_district = OrganizationDistrict.new(@facility.district, @organization)
  end

  def set_organization
    @organization = @facility.organization
  end

  def users_for_facility
    User.joins(:blood_pressures).where('blood_pressures.facility_id = ?', @facility.id).order(:full_name).distinct
  end

  def user_analytics
    users_for_facility.map { |user| [user, Analytics::UserAnalytics.new(user, @facility)] }.to_h
  end
end

