class MergePatientService

  def initialize(patient_record)
    @patient_record = patient_record
  end

  def merge
    patient = Patient.new(patient_record.except(:address, :phone_numbers))
    patient.address = merge_address(patient_record[:address]) if patient_record[:address].present?
    patient.phone_numbers = merge_phone_numbers(patient_record)
    MergeRecord.merge_by_id(patient)
  end

  private

  attr_reader :patient_record

  def merge_address(address_params)
    address = Address.new(address_params)
    MergeRecord.merge_by_id(address)
  end

  def merge_phone_numbers(patient_record)
    patient_record[:phone_numbers].to_a.map do |phone_number_params|
      merge_phone_number phone_number_params
    end
  end

  def merge_phone_number(phone_number_params)
    phone_number = PhoneNumber.new(phone_number_params)
    MergeRecord.merge_by_id(phone_number)
  end
end