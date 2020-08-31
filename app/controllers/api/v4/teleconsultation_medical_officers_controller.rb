class Api::V4::TeleconsultationMedicalOfficersController < APIController
  def sync_to_user
    render status: 200, json: {}
  end
end
