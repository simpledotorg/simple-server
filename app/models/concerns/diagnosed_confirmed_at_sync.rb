module DiagnosedConfirmedAtSync
  extend ActiveSupport::Concern

  included do
    after_commit :sync_diagnosed_confirmed_at, on: [:create, :update]
  end

  private

  def sync_diagnosed_confirmed_at
    patient = extract_patient
    return unless patient

    mh = MedicalHistory.where(patient_id: patient.id, deleted_at: nil)
                       &.order(device_updated_at: :desc)
                       &.first
    return unless mh

    valid_htn = mh.htn_diagnosed_at.present? && %w[yes no].include?(mh.hypertension)
    valid_dm = mh.dm_diagnosed_at.present? && %w[yes no].include?(mh.diabetes)

    return unless valid_htn || valid_dm

    earliest = [
      (mh.htn_diagnosed_at if valid_htn),
      (mh.dm_diagnosed_at if valid_dm)
    ].compact.min

    return if earliest.blank?

    if patient.diagnosed_confirmed_at.nil?
      patient.update_columns(diagnosed_confirmed_at: earliest)
    end
  end

  def extract_patient
    case self
    when Patient
      self
    when MedicalHistory
      patient
    end
  end
end
