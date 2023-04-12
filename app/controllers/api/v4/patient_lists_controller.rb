class Api::V4::PatientListsController < DownloadApiController
  def district
    patients = current_facility_group.assigned_patients

    render json: PatientsWithHistoryExporter.json(patients, display_blood_sugars: true), status: :ok
  end
end