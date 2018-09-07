class Qa::PurgesController < APIController
  skip_before_action :authenticate, only: [:purge_patient_data]
  before_action :validate_access

  def purge_patient_data
    return unless FeatureToggle.enabled?('PURGE_ENDPOINT_FOR_QA')
    BloodPressure.delete_all
    PrescriptionDrug.delete_all
    PatientPhoneNumber.delete_all
    Communication.delete_all
    Appointment.delete_all
    Patient.delete_all
    Address.delete_all

    head :ok
  end

  def validate_access
    purge_access_token = ENV.fetch('PURGE_URL_ACCESS_TOKEN')
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, purge_access_token)
    end
  end
end