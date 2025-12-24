module Api
  module V3
    module Historical
      class PrescriptionDrugsController < HistoricalSyncController
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
          record_params = Api::V3::PrescriptionDrugTransformer
            .from_request(prescription_drug_params)
            .merge(metadata)

          prescription_drug = PrescriptionDrug.find_or_initialize_by(id: record_params[:id])
          safe_assign_attributes(prescription_drug, record_params)

          if prescription_drug.save(validate: false)
            {record: prescription_drug}
          else
            {
              errors_hash: {
                id: record_params[:id],
                error_type: "save_failed",
                message: prescription_drug.errors.full_messages.join(", ")
              }
            }
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
    end
  end
end
