# frozen_string_literal: true

class Api::V3::PrescriptionDrugsController < Api::V3::SyncController
  def sync_from_user
    __sync_from_user__(prescription_drugs_params)
  end

  def sync_to_user
    __sync_to_user__("prescription_drugs")
  end

  def metadata
    {user_id: current_user.id}
  end

  private

  def merge_if_valid(prescription_drug_params)
    validator = Api::V3::PrescriptionDrugPayloadValidator.new(prescription_drug_params)
    logger.debug "Prescription Drug had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.check_invalid?
      {errors_hash: validator.errors_hash}
    else
      record_params = Api::V3::PrescriptionDrugTransformer
        .from_request(prescription_drug_params)
        .merge(metadata)

      prescription_drug = PrescriptionDrug.merge(record_params)
      {record: prescription_drug}
    end
  end

  def transform_to_response(prescription_drug)
    Api::V3::PrescriptionDrugTransformer.to_response(prescription_drug)
  end

  def prescription_drugs_params
    params.require(:prescription_drugs).map do |prescription_drug_params|
      prescription_drug_params.permit(
        :id,
        :name,
        :dosage,
        :rxnorm_code,
        :is_protocol_drug,
        :is_deleted,
        :patient_id,
        :facility_id,
        :frequency,
        :duration_in_days,
        :teleconsultation_id,
        :created_at,
        :updated_at,
        :deleted_at
      )
    end
  end
end
