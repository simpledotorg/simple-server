class Reports::PatientListsController < AdminController
  skip_after_action :verify_authorized, if: -> { current_admin.permissions_v2_enabled? }
  after_action :verify_authorization_attempted, if: -> { current_admin.permissions_v2_enabled? }

  def show
    scope = if current_admin.permissions_v2_enabled?
      if region_class == "facility_group"
        authorize_v2 { current_admin.accessible_facility_groups(:view_pii) }
      else
        authorize_v2 { current_admin.accessible_facilities(:view_pii) }
      end
    else
      authorize([:cohort_report, region_class.classify.constantize], :patient_list?)
    end
    @region = scope.find_by!(slug: params[:id])

    recipient_email = current_admin.email
    download_params = if region_class == "facility_group"
      {id: @region.id}
    else
      {facility_id: @region.id}
    end

    PatientListDownloadJob.perform_later(recipient_email, region_class, download_params)
    redirect_back(fallback_location: reports_region_path(@region, report_scope: params[:report_scope]))
  end

  private

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
      raise ActiveRecord::RecordNotFound, "unknown report scope #{filtered_params[:report_scope].inspect}"
    end
  end
end
