class Reports::PatientListsController < AdminController
  skip_after_action :verify_policy_scoped
  before_action :find_region

  def show
    if current_admin.permissions_v2_enabled?
      authorize_v2 { current_admin.accessible_facilities(:view_reports).any? }
    else
      authorize(:dashboard, :show?)
    end

    recipient_email = current_admin.email

    download_params = if region_class = "facility_group"
      {id: @region.id}
    else
      {facility_id: @region.id}
    end

    PatientListDownloadJob.perform_later(recipient_email, region_class, download_params)

    redirect_back(fallback_location: reports_region_path(@region))
  end

  private

  def find_region
    slug = filtered_params[:id]
    klass = region_class.classify.constantize
    @region = klass.find_by!(slug: slug)
  end

  def filtered_params
    params.permit(:id, :report_scope)
  end

  def region_class
    @region_class ||= case filtered_params[:report_scope]
    when "district"
      "facility_group"
    when "facility"
      "facility"
    else
      raise ActiveRecord::RecordNotFound, "unknown report scope #{filtered_params[:report_scope]}"
    end
  end
end
