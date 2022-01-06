# frozen_string_literal: true

class Reports::PatientListsController < AdminController
  def show
    scope = if region_class == "facility_group"
      authorize { current_admin.accessible_district_regions(:view_pii) }
    else
      authorize { current_admin.accessible_facility_regions(:view_pii) }
    end

    @region = scope.find_by!(slug: params[:id])
    recipient_email = current_admin.email
    download_params = case region_class
    when "facility_group"
      {id: @region.source_id}
    else
      {facility_id: @region.source_id}
    end

    PatientListDownloadJob.perform_later(
      recipient_email,
      region_class,
      download_params,
      with_medication_history: with_medication_history?
    )
    redirect_back(
      fallback_location: reports_region_path(@region, report_scope: params[:report_scope]),
      notice: I18n.t("patient_list_email.notice",
        model_type: filtered_params[:report_scope],
        model_name: @region.name)
    )
  end

  private

  def with_medication_history?
    params[:medication_history] == "true"
  end

  def filtered_params
    params.permit(:id, :report_scope, :medication_history)
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
