class DeduplicatePatients
  def initialize(patients)
    @patients = patients.sort_by(&:recorded_at)
  end

  def earliest_patient
    @patients.first
  end

  def latest_patient
    @patients.last
  end

  def merge
    patient_ids = @patients.pluck(:id)
    Rails.logger.info "Merging patients #{patient_ids}"

    new_patient = ActiveRecord::Base.transaction do
      new_patient = create_patient
      create_prescription_drugs(new_patient)
      create_medical_history(new_patient)
      create_phone_numbers(new_patient)
      create_patient_business_identifiers(new_patient)
      create_encounters_and_observables(new_patient)
      create_appointments(new_patient)
      create_teleconsultations(new_patient)
      mark_as_merged(new_patient)
      new_patient.reload
    end

    Rails.logger.info "Merged patients #{patient_ids} into patient #{new_patient.id}"
    new_patient
  end

  def mark_as_merged(new_patient)
    @patients.map { |patient| patient.update!(merged_into_patient_id: new_patient.id) }
    @patients.map(&:discard_data)
  end

  def create_patient
    attributes = {
      id: SecureRandom.uuid,
      full_name: latest_patient.full_name,
      gender: latest_patient.gender,
      reminder_consent: latest_patient.reminder_consent,
      recorded_at: earliest_patient.recorded_at,
      registration_facility: earliest_patient.registration_facility,
      registration_user: earliest_patient.registration_user,
      device_created_at: earliest_patient.device_created_at,
      device_updated_at: earliest_patient.device_updated_at,
      assigned_facility: latest_patient.assigned_facility,
      address: create_address,
      **age_and_dob
    }
    Patient.create!(attributes)
  end

  def age_and_dob
    if @patients.map(&:date_of_birth).any?
      {
        date_of_birth: latest_available_property(:date_of_birth),
        age: nil,
        age_updated_at: nil
      }
    else
      latest_patient_with_age = latest_patient_with_property(:age)
      {
        date_of_birth: nil,
        age: latest_patient_with_age.age,
        age_updated_at: latest_patient_with_age.age_updated_at
      }
    end
  end

  def create_prescription_drugs(patient)
    current_prescription_drugs = latest_patient.prescribed_drugs
    old_prescription_drugs =
      PrescriptionDrug
        .where(patient_id: @patients)
        .where.not(id: current_prescription_drugs)

    old_prescription_drugs.each { |pd| pd.is_deleted = true }
    create_cloned_records!(patient, PrescriptionDrug, current_prescription_drugs + old_prescription_drugs)
  end

  def create_medical_history(patient)
    medical_histories = MedicalHistory.where(patient_id: @patients).order(:device_updated_at)

    MedicalHistory.create!(consolidate_medical_history(medical_histories).merge(
      id: SecureRandom.uuid,
      patient_id: patient.id,
      device_created_at: medical_histories.last.device_created_at,
      device_updated_at: medical_histories.last.device_updated_at,
      user_id: medical_histories.last.user_id
    ))
  end

  def consolidate_medical_history(medical_histories)
    attributes_to_merge = [
      *MedicalHistory::MEDICAL_HISTORY_QUESTIONS,
      :prior_heart_attack_boolean,
      :prior_stroke_boolean,
      :chronic_kidney_disease_boolean,
      :receiving_treatment_for_hypertension_boolean,
      :diabetes_boolean,
      :diagnosed_with_hypertension_boolean,
      :hypertension
    ]
    precedence = {"yes" => 0, true => 1, "no" => 2, false => 3, "unknown" => 4, nil => 5}

    attributes_to_merge.each_with_object({}) do |attribute, merged_attributes|
      merged_attributes[attribute] = medical_histories
        .map { |patient| patient[attribute] }
        .min_by { |value| precedence.fetch(value, precedence.size) }
    end
  end

  def create_phone_numbers(patient)
    phone_numbers =
      PatientPhoneNumber
        .unscoped
        .kept
        .select("DISTINCT ON (number) *")
        .where(patient_id: @patients)
        .order("number, device_updated_at DESC")

    create_cloned_records!(patient, PatientPhoneNumber, phone_numbers)
  end

  def create_patient_business_identifiers(patient)
    business_identifiers =
      PatientBusinessIdentifier
        .select("DISTINCT ON (identifier) *")
        .where(patient_id: @patients)
        .order("identifier, device_updated_at DESC")

    create_cloned_records!(patient, PatientBusinessIdentifier, business_identifiers)
  end

  def create_encounters_and_observables(patient)
    encounters = Encounter.where(patient: @patients)
    encounters.map do |encounter|
      new_encounter = Encounter.create!(
        copyable_attributes(encounter)
          .merge(id: Encounter.generate_id(encounter.facility.id, patient.id, encounter.encountered_on),
                 patient_id: patient.id)
      )

      encounter.observations.map do |observation|
        observable = observation.observable
        new_observable = create_cloned_record!(patient, observable.class, observable)
        Observation.create!(user_id: observation.user_id, observable: new_observable, encounter: new_encounter)
      end
    end
  end

  def create_appointments(patient)
    create_cloned_records!(patient, Appointment, Appointment.where(patient_id: @patients))

    stale_appointments = patient.appointments.status_scheduled.order(device_updated_at: :desc).drop(1)
    stale_appointments.map { |appointment| appointment.update!(status: :cancelled) }
  end

  def create_teleconsultations(patient)
    create_cloned_records!(patient, Teleconsultation, Teleconsultation.where(patient_id: @patients))
  end

  def create_address
    Address.create!(copyable_attributes(latest_available_property(:address)).merge(id: SecureRandom.uuid))
  end

  def latest_available_property(property)
    @patients.map { |patient| patient.send(property) }.compact.last
  end

  def latest_patient_with_property(property)
    @patients.reverse.find { |patient| patient.send(property).present? }
  end

  def create_cloned_records!(patient, klass, records)
    records.map do |record|
      create_cloned_record!(patient, klass, record)
    end
  end

  def create_cloned_record!(patient, klass, record)
    klass.create!(
      copyable_attributes(record)
        .merge(id: SecureRandom.uuid, patient_id: patient.id)
    )
  end

  def copyable_attributes(record)
    record.attributes
      .with_indifferent_access
      .except(:id, :patient_id, :created_at, :updated_at)
  end
end
