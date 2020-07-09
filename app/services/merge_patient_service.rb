class MergePatientService
  def initialize(payload, request_metadata:)
    @payload = payload
    @request_metadata = request_metadata
  end

  def merge
    existing_patient = Patient.with_discarded.find_by(id: payload['id'])
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

    discard_patient_data(merged_patient, existing_patient)
  end

  private

  attr_reader :request_metadata, :payload

  def set_metadata(patient_params)
    new_patient_params = patient_params.merge(new_patient_metadata)
    merge_status = Patient.compute_merge_status(new_patient_params)

    if merge_status == :new
      new_patient_params
    else
      patient_params.merge(existing_patient_metadata(patient_params[:id]))
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

  def discard_patient_data(patient, existing_patient)
    if patient.deleted_at.present? && existing_patient&.deleted_at.nil?
      # Patient has been soft-deleted by the client, server should soft-delete the patient and their associated data
      patient.update(deleted_by_user_id: request_metadata[:request_user_id])
      patient.discard_data
    end

    patient
  end

  def new_patient_metadata
    {registration_facility_id: request_metadata[:request_facility_id],
     registration_user_id: request_metadata[:request_user_id]}
  end

  def existing_patient_metadata(id)
    Patient.find(id).slice(*new_patient_metadata.keys)
  end

  def log_update_discarded_patient(merged_patient)
    NewRelic::Agent.increment_metric('MergePatientService/update_discarded_patient') if merged_patient.discarded?
  end
end
