class MergePatientService
  def initialize(payload, metadata_keys: [])
    @payload = payload
    @metadata_keys = metadata_keys
  end

  def merge
    existing_patient_attributes = Patient.with_discarded.find_by(id: payload['id'])&.attributes
    merged_address = Address.merge(payload[:address]) if payload[:address].present?

    patient_attributes = payload
                           .except(:address, :phone_numbers, :business_identifiers)
                           .yield_self { |attrs| set_patient_address(attrs, merged_address) }
                           .yield_self { |attrs| set_metadata(attrs) }
                           .yield_self { |attrs| set_assigned_facility(attrs) }

    merged_patient = Patient.merge(patient_attributes)
    merged_patient.address = merged_address

    merged_phone_numbers = merge_phone_numbers(payload[:phone_numbers], merged_patient)
    merged_business_identifiers = merge_business_identifiers(payload[:business_identifiers], merged_patient)

    if (merged_address.present? && merged_address.merged?) || merged_phone_numbers.any?(&:merged?) || merged_business_identifiers.any?(&:merged?)
      merged_patient.touch

      #
      # This is a rare scenario that might be possible in the future.
      # If the client allows the user to update the patient's address or phone_number,
      # there might be a case where the address or phone_number for a patient is updated for a discarded patient.
      #
      # These updates should not ideally be made at all because they will be invisible to the user.
      #
      # We can fix this issue, but it requires re-working the merge function, so we'll currently just
      # track the incidence rate, so we can plan for a fix if necessary.
      log_update_discarded_patient(merged_patient)
    end

    if (merged_patient.deleted_at.present? && existing_patient_attributes&.dig('deleted_at').nil?)
      # Patient has been soft-deleted by the client, server should soft-delete the patient and their associated data
      # patient_attributes[:metadata][:registration_user_id] contains the current user's id
      merged_patient.update(deleted_by_user_id: patient_attributes[:metadata][:registration_user_id])
      merged_patient.discard_data
    end

    merged_patient
  end

  private

  attr_reader :metadata_keys, :payload

  def set_metadata(single_patient_params)
    if Patient.compute_merge_status(single_patient_params) == Set[:updated, :old]
      existing_metadata = Patient.find(single_patient_params[:id]).slice(*metadata_keys)
      single_patient_params.merge(existing_metadata)
    else
      single_patient_params
    end
  end

  def set_patient_address(patient_attributes, address)
    patient_attributes["address_id"] = address.id if address.present?
    patient_attributes
  end

  def set_assigned_facility(patient_attributes)
    if patient_attributes[:assigned_facility_id].nil?
      patient_attributes[:assigned_facility_id] = patient_attributes[:registration_facility_id]
    end

    patient_attributes
  end

  def merge_phone_numbers(phone_number_params, patient)
    return [] unless phone_number_params.present?
    phone_number_params.map do |single_phone_number_params|
      PatientPhoneNumber.merge(single_phone_number_params.merge(patient: patient))
    end
  end

  def merge_business_identifiers(business_identifier_params, patient)
    return [] unless business_identifier_params.present?
    business_identifier_params.map do |single_business_identifier_params|
      PatientBusinessIdentifier.merge(single_business_identifier_params.merge(patient: patient))
    end
  end

  def log_update_discarded_patient(merged_patient)
    NewRelic::Agent.increment_metric('MergePatientService/update_discarded_patient') if merged_patient.discarded?
  end
end
