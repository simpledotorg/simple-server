class Reports::PatientListsController < AdminController
  def show
    scope = if region_class == "facility_group"
      authorize { current_admin.accessible_facility_groups(:view_pii) }
    else
      authorize { current_admin.accessible_facilities(:view_pii) }
    end

    if region_class == "facility_district"
      @region = FacilityDistrict.new(name: params[:id], scope: scope)
    else
      @region = scope.find_by!(slug: params[:id])
    end

    recipient_email = current_admin.email
    download_params = case region_class
    when "facility_group"
      {id: @region.id}
    when "facility_district"
      {name: @region.name, user_id: current_admin.id}
    else
      {facility_id: @region.id}
    end

    PatientListDownloadJob.perform_later(recipient_email, region_class, download_params)
    redirect_back(
      fallback_location: reports_region_path(@region, report_scope: params[:report_scope]),
      notice: I18n.t("patient_list_email.notice",
        model_type: filtered_params[:report_scope],
        model_name: @region.name)
    )
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
    when "facility_district"
      "facility_district"
    else
      raise ActiveRecord::RecordNotFound, "unknown report scope #{filtered_params[:report_scope].inspect}"
    end
  end
end
