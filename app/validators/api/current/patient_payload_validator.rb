class Api::Current::PatientPayloadValidator < Api::Current::NewPayloadValidator

  # TODO: Add validation to model
  def presence_of_age
    unless date_of_birth.present? || (age.present? && age_updated_at.present?)
      errors.add(:age, 'Either date_of_birth or age and age_updated_at should be present')
    end
  end

  # TODO: Add validation to model
  def past_date_of_birth
    if date_of_birth.present? && date_of_birth.to_s.to_time > Date.current
      errors.add(:date_of_birth, "can't be in the future")
    end
  end

  def schema
    Api::Current::Schema.patient_sync_from_user_request
  end
end
