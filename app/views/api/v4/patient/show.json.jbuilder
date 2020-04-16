json.patient do
  json.patient_id @current_patient.id
  json.full_name @current_patient.full_name
  json.age @current_patient.age
  json.age_updated_at @current_patient.age_updated_at
  json.gender @current_patient.gender
  json.status @current_patient.status
  json.date_of_birth @current_patient.date_of_birth
  json.recorded_at @current_patient.recorded_at
  json.reminder_consent @current_patient.reminder_consent

  json.phone_numbers @current_patient.phone_numbers do |phone_number|
    json.phone_number_id phone_number.id
    json.number phone_number.number
  end

  if @current_patient.address.present?
    address = @current_patient.address

    json.address do
      json.address_id address.id
      json.street_address address.street_address
      json.village_or_colony address.village_or_colony
      json.zone address.zone
      json.district address.district
      json.zone address.zone
      json.state address.state
      json.country address.country
      json.pin address.pin
    end
  end

  json.registration_facility do
    facility = @current_patient.registration_facility

    json.name facility.name
    json.street_address facility.street_address
    json.village_or_colony facility.village_or_colony
    json.district facility.district
    json.state facility.state
    json.country facility.country
    json.pin facility.pin
  end

  if @current_patient.medical_history.present?
    history = @current_patient.medical_history

    json.medical_history do
      json.chronic_kidney_disease history.chronic_kidney_disease
      json.diabetes history.diabetes
      json.diagnosed_with_hypertension history.diagnosed_with_hypertension
      json.hypertension history.hypertension
      json.prior_heart_attack history.prior_heart_attack
      json.prior_stroke history.prior_stroke
      json.receiving_treatment_for_hypertension history.receiving_treatment_for_hypertension
    end
  end

  json.blood_pressures @current_patient.blood_pressures do |bp|
    json.systolic bp.systolic
    json.diastolic bp.diastolic
    json.recorded_at bp.recorded_at

    json.facility do
      json.name bp.facility.name
      json.street_address bp.facility.street_address
      json.village_or_colony bp.facility.village_or_colony
      json.district bp.facility.district
      json.state bp.facility.state
      json.country bp.facility.country
      json.pin bp.facility.pin
    end
  end

  json.appointments @current_patient.appointments do |appointment|
    json.scheduled_date appointment.scheduled_date

    json.facility do
      json.name appointment.facility.name
      json.street_address appointment.facility.street_address
      json.village_or_colony appointment.facility.village_or_colony
      json.district appointment.facility.district
      json.state appointment.facility.state
      json.country appointment.facility.country
      json.pin appointment.facility.pin
    end
  end
end
