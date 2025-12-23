module Api
  module V3
    module Historical
      class PatientsController < HistoricalSyncController
        def sync_from_user
          __sync_from_user__(patients_params)
        end

        def sync_to_user
          unscope_associations do
            __sync_to_user__("patients")
          end
        end

        def transform_to_response(patient)
          Api::V3::PatientTransformer.to_nested_response(patient)
        end

        private

        def unscope_associations
          Address.unscoped do
            PatientPhoneNumber.unscoped do
              PatientBusinessIdentifier.unscoped do
                yield
              end
            end
          end
        end

        def merge_if_valid(single_patient_params)
          transformed =
            Api::V3::PatientTransformer.from_nested_request(single_patient_params)

          phone_numbers = transformed.delete(:phone_numbers) || []
          address_attrs = transformed.delete(:address)
          identifiers = transformed.delete(:business_identifiers) || []

          patient = Patient.find_or_initialize_by(id: transformed[:id])
          patient.registration_user_id ||= current_user.id

          safe_assign_attributes(patient, transformed)

          unless patient.save(validate: false)
            return {
              errors_hash: {
                id: transformed[:id],
                error_type: "patient_save_failed",
                message: patient.errors.full_messages.join(", ")
              }
            }
          end

          process_address(patient, address_attrs) if address_attrs.present?
          process_phone_numbers(patient, phone_numbers)
          process_business_identifiers(patient, identifiers)

          {record: patient}
        end

        def process_address(patient, attrs)
          address =
            attrs[:id].present? ? Address.find_or_initialize_by(id: attrs[:id]) : patient.build_address

          safe_assign_attributes(address, attrs)
          address.save(validate: false)

          patient.update_column(:address_id, address.id)
        end

        def process_phone_numbers(patient, phone_numbers)
          phone_numbers.each do |attrs|
            phone =
              PatientPhoneNumber.find_or_initialize_by(id: attrs[:id])

            safe_assign_attributes(phone, attrs.merge(patient_id: patient.id))
            phone.save(validate: false)
          end
        end

        def process_business_identifiers(patient, identifiers)
          identifiers.each do |attrs|
            if attrs[:metadata].is_a?(String)
              attrs[:metadata] = begin
                JSON.parse(attrs[:metadata])
              rescue
                attrs[:metadata]
              end
            end

            identifier =
              PatientBusinessIdentifier.find_or_initialize_by(id: attrs[:id])

            safe_assign_attributes(identifier, attrs.merge(patient_id: patient.id))
            identifier.save(validate: false)
          end
        end

        def patients_params
          patient_attributes = params.require(:patients)

          patient_attributes.map do |p|
            p.permit(
              :id,
              :full_name,
              :age,
              :age_updated_at,
              :gender,
              :status,
              :date_of_birth,
              :created_at,
              :updated_at,
              :recorded_at,
              :reminder_consent,
              :deleted_at,
              :deleted_reason,
              :registration_facility_id,
              :assigned_facility_id,
              :eligible_for_reassignment,
              address: %i[
                id street_address village_or_colony zone district state country pin created_at updated_at
              ],
              phone_numbers: %i[
                id number phone_type active created_at updated_at
              ],
              business_identifiers: %i[
                id identifier identifier_type metadata metadata_version created_at updated_at deleted_at
              ]
            )
          end
        end
      end
    end
  end
end
