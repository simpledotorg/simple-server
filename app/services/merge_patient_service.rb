class MergePatientService

  def initialize(patient_record)
    @patient_record = patient_record
  end

  def merge
    patient = Patient.new(patient_record.except(:address, :phone_numbers))

    merged_address = nil
    if patient_record[:address]
      merged_address  = merge_address(patient_record[:address])
      patient.address = merged_address.record
    end

    merged_phone_numbers = []
    if patient_record[:phone_numbers].present?
      merged_phone_numbers  = merge_phone_numbers(patient_record[:phone_numbers])
      patient.phone_numbers = merged_phone_numbers.map(&:record)
    end

    merged_patient = MergeableRecord.new(patient).merge

    if (merged_address.present? && merged_address.merged?) || merged_phone_numbers.any?(&:merged?)
      merged_patient.record.update_column(:updated_on_server_at, Time.now)
    end

    merged_patient.record
  end

  private

  attr_reader :patient_record

  def merge_address(address_params)
    MergeableRecord.new(Address.new(address_params)).merge
  end

  def merge_phone_numbers(phone_number_params)
    phone_number_params.map do |single_phone_number_params|
      MergeableRecord.new(PhoneNumber.new(single_phone_number_params)).merge
    end
  end
end