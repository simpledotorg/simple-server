class MergePatientService
  def initialize(payload, request_metadata:)
    @payload = payload
    @request_metadata = request_metadata
  end

  def merge
    merged_address = Address.merge(payload[:address]) if payload[:address].present?

    patient_attributes =
      payload
        .except(:address, :phone_numbers, :business_identifiers)
        .yield_self { |params| set_metadata(params) }
        .yield_self { |params| set_address_id(params, merged_address) }
        .yield_self { |params| set_assigned_facility(params) }

    merged_patient = Patient.merge(patient_attributes)
    merged_patient.address = merged_address
    merged_phone_numbers = merge_phone_numbers(payload[:phone_numbers], merged_patient)
    merged_business_ids = merge_business_identifiers(payload[:business_identifiers], merged_patient)

    touch_patient(merged_patient) if associations_updated?(merged_address, merged_phone_numbers, merged_business_ids)

    if should_discard_patient_data?(merged_patient, patient_attributes)
      discard_patient_data(merged_patient)
    end

    merged_patient
  end

  private

  def should_discard_patient_data?(merged_patient, merged_attributes)
    merged_patient.merge_status == :updated &&
      merged_attributes[:deleted_at].present? &&
      merged_patient.discarded?
  end

  attr_reader :payload, :request_metadata

  def set_metadata(patient_params)
    new_patient_params = patient_params.merge(new_patient_metadata)
    merge_status = Patient.compute_merge_status(new_patient_params)

    case merge_status
      when :invalid
        patient_params
      when :new
        new_patient_params
      else
        patient_params.merge(existing_patient_metadata)
    end
  end

  def set_address_id(patient_params, address)
    patient_params["address_id"] = address.id if address.present?
    patient_params
  end

  def set_assigned_facility(patient_params)
    if patient_params[:assigned_facility_id].nil?
      patient_params[:assigned_facility_id] = patient_params[:registration_facility_id]
    end

    patient_params
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

  def discard_patient_data(patient)
    patient.update(deleted_by_user_id: request_metadata[:request_user_id])
    patient.discard_data(reason: patient.deleted_reason)
  end

  def associations_updated?(address, phone_numbers, business_ids)
    (address.present? && address.merged?) || phone_numbers.any?(&:merged?) || business_ids.any?(&:merged?)
  end

  def touch_patient(patient)
    patient.touch
    #
    # This is a rare scenario that might be possible in the future.
    # If the client allows the user to update the patient's address or phone_number,
    # there might be a case where the address or phone_number for a patient is updated for a discarded patient.
    #
    # These updates should not ideally be made at all because they will be invisible to the user.
    #
    # We can fix this issue, but it requires re-working the merge function, so we'll currently just
    # track the incidence rate, so we can plan for a fix if necessary.
    log_update_discarded_patient if patient.discarded?
  end

  def new_patient_metadata
    {
      registration_facility_id: payload[:registration_facility_id] || request_metadata[:request_facility_id],
      registration_user_id: request_metadata[:request_user_id]
    }
  end

  def existing_patient_metadata
    existing_patient.slice(*new_patient_metadata.keys)
  end

  def existing_patient
    Patient.with_discarded.find_by(id: payload["id"])
  end

  def log_update_discarded_patient
    Statsd.instance.increment("#{self.class}.update_discarded_patient")
  end
end
