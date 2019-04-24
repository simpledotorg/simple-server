class MergePatientService

  def initialize(payload)
    @payload = payload
  end

  def merge
    merged_address = Address.merge(payload[:address]) if payload[:address].present?

    patient_attributes = payload.except(:address, :phone_numbers, :business_identifiers)

    patient_attributes['address_id'] = merged_address.id if merged_address.present?
    merged_patient = Patient.merge(attributes_with_metadata(patient_attributes))
    merged_patient.address = merged_address

    merged_phone_numbers = merge_phone_numbers(payload[:phone_numbers], merged_patient)
    merged_business_identifiers = merge_business_identifiers(payload[:business_identifiers], merged_patient)

    if (merged_address.present? && merged_address.merged?) || merged_phone_numbers.any?(&:merged?) || merged_business_identifiers.any?(&:merged?)
      merged_patient.touch
    end

    merged_patient
  end

  private

  def attributes_with_metadata(patient_attributes)
    with_request_metadata = patient_attributes.merge(patient_attributes[:metadata]).except(:metadata)
    metadata_keys = patient_attributes[:metadata].keys

    case Patient.compute_merge_status(with_request_metadata)
    when :new
      with_request_metadata
    when Set[:updated, :old]
      existing_metadata = Patient.find(patient_attributes[:id]).slice(*metadata_keys)
      patient_attributes.merge(existing_metadata).except(:metadata)
    else
      patient_attributes.except(:metadata)
    end
  end

  attr_reader :payload

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
end
