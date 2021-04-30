json.id patient.id
json.full_name patient.full_name
json.age patient.current_age
json.gender patient.gender
json.status patient.status
json.recorded_at patient.recorded_at
json.reminder_consent patient.reminder_consent

json.phone_numbers patient.phone_numbers do |phone_number|
  json.id phone_number.id
  json.number phone_number.number
end

if patient.address.present?
  address = patient.address

  json.address do
    json.id address.id
    json.street_address address.street_address
    json.village_or_colony address.village_or_colony
    json.district address.district
    json.zone address.zone
    json.state address.state
    json.country address.country
    json.pin address.pin
  end
end

json.registration_facility do
  facility = patient.registration_facility

  json.id facility.id
  json.name facility.name
  json.street_address facility.street_address
  json.village_or_colony facility.village_or_colony
  json.district facility.district
  json.state facility.state
  json.country facility.country
  json.pin facility.pin
end

if patient.medical_history.present?
  history = patient.medical_history

  json.medical_history do
    json.chronic_kidney_disease history.chronic_kidney_disease
    json.diabetes history.diabetes
    json.hypertension history.hypertension
    json.prior_heart_attack history.prior_heart_attack
    json.prior_stroke history.prior_stroke
  end
end

json.blood_pressures patient.blood_pressures do |blood_pressure|
  json.systolic blood_pressure.systolic
  json.diastolic blood_pressure.diastolic
  json.recorded_at blood_pressure.recorded_at

  json.facility do
    json.id blood_pressure.facility.id
    json.name blood_pressure.facility.name
    json.street_address blood_pressure.facility.street_address
    json.village_or_colony blood_pressure.facility.village_or_colony
    json.district blood_pressure.facility.district
    json.state blood_pressure.facility.state
    json.country blood_pressure.facility.country
    json.pin blood_pressure.facility.pin
  end
end

json.blood_sugars patient.blood_sugars do |blood_sugar|
  json.blood_sugar_value blood_sugar.blood_sugar_value
  json.blood_sugar_type blood_sugar.blood_sugar_type
  json.recorded_at blood_sugar.recorded_at

  json.facility do
    json.id blood_sugar.facility.id
    json.name blood_sugar.facility.name
    json.street_address blood_sugar.facility.street_address
    json.village_or_colony blood_sugar.facility.village_or_colony
    json.district blood_sugar.facility.district
    json.state blood_sugar.facility.state
    json.country blood_sugar.facility.country
    json.pin blood_sugar.facility.pin
  end
end

json.appointments patient.appointments do |appointment|
  json.scheduled_date appointment.scheduled_date
  json.status appointment.status

  json.facility do
    json.id appointment.facility.id
    json.name appointment.facility.name
    json.street_address appointment.facility.street_address
    json.village_or_colony appointment.facility.village_or_colony
    json.district appointment.facility.district
    json.state appointment.facility.state
    json.country appointment.facility.country
    json.pin appointment.facility.pin
  end
end

json.medications patient.current_prescription_drugs do |drug|
  json.name drug.name
  json.dosage drug.dosage
  json.rxnorm_code drug.rxnorm_code
  json.is_protocol_drug drug.is_protocol_drug
end
