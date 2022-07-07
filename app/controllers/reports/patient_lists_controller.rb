class Reports::PatientListsController < AdminController
  def show
    @region = scope.find_by!(slug: params[:id])

    PatientListDownloadJob.perform_async(
      current_admin.email,
      region_class,
      download_params(region_class)
    )
    redirect_back(
      fallback_location: reports_region_path(@region, report_scope: params[:report_scope]),
      notice: I18n.t("patient_list_email.notice",
        model_type: filtered_params[:report_scope],
        model_name: @region.name)
    )
  end

  def diabetes
    @region = scope.find_by!(slug: params[:id])

    PatientListDownloadJob.perform_async(
      current_admin.email,
      region_class,
      download_params(region_class),
      diagnosis: :diabetes
    )
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
    else
      raise ActiveRecord::RecordNotFound, "unknown report scope #{filtered_params[:report_scope].inspect}"
    end
  end

  def scope
    if region_class == "facility_group"
      authorize { current_admin.accessible_district_regions(:view_pii) }
    else
      authorize { current_admin.accessible_facility_regions(:view_pii) }
    end
  end

  def download_params(region_class)
    case region_class
    when "facility_group"
      {id: @region.source_id}
    else
      {facility_id: @region.source_id}
    end
  end
end
