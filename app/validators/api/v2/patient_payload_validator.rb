class Api::V2::PatientPayloadValidator < Api::V3::PatientPayloadValidator
  attr_accessor(
    :id,
    :full_name,
    :age,
    :gender,
    :date_of_birth,
    :status,
    :age_updated_at,
    :created_at,
    :updated_at,
    :deleted_at,
    :address,
    :phone_numbers,
    :business_identifiers,
    :contacted_by_counsellor,
    :could_not_contact_reason,
    :call_result
  )

  def schema
    Api::V2::Models.nested_patient
  end
end
