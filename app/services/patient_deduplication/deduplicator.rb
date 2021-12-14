module PatientDeduplication
  class Deduplicator
    def initialize(patients, user: nil)
      @patients = patients.sort_by(&:recorded_at)
      @user_id = user&.id
      @errors = []

      validate_patients(patients)
    end

    attr_reader :errors

    def earliest_patient
      @patients.first
    end

    def latest_patient
      @patients.last
    end

    def merge
      return if errors.present?
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
    rescue => e
      # Bad data can cause our merge logic to breakdown in unpredictable ways.
      # We want to report any such errors and look into them on a per case basis.
      handle_error(e)
    end

    def handle_error(e)
      error_details = {exception: e, patient_ids: @patients.map(&:id)}
      @errors << error_details
      Sentry.capture_message("Failed to merge duplicate patients", extra: error_details)
    end

    def mark_as_merged(new_patient)
      @patients.each do |patient|
        track(Patient, patient, new_patient)
      end
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
        status: latest_patient.status,
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

      new_medical_history = MedicalHistory.create!(consolidate_medical_history(medical_histories).merge(
        id: SecureRandom.uuid,
        patient_id: patient.id,
        device_created_at: medical_histories.last.device_created_at,
        device_updated_at: medical_histories.last.device_updated_at,
        user_id: medical_histories.last.user_id
      ))

      medical_histories.each { |medical_history| track(MedicalHistory, medical_history, new_medical_history) }
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
      encounters.each do |encounter|
        encounter_id = Encounter.generate_id(encounter.facility.id, patient.id, encounter.encountered_on)
        existing_encounter = Encounter.find_by(id: encounter_id)
        new_encounter = existing_encounter || Encounter.create!(
          copyable_attributes(encounter)
            .merge(id: encounter_id,
              patient_id: patient.id)
        )
        track(Encounter, encounter, new_encounter) unless existing_encounter.present?

        encounter.observations.each do |observation|
          observable = observation.observable

          next unless observable.present?

          new_observable = create_cloned_record!(patient, observable.class, observable)
          new_observation = Observation.create!(user_id: observation.user_id, observable: new_observable, encounter: new_encounter)
          track(Observation, observation, new_observation)
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
      new_address = Address.create!(copyable_attributes(latest_available_property(:address)).merge(id: SecureRandom.uuid))
      @patients.each { |patient| track(Address, patient.address, new_address) if patient.address.present? }
      new_address
    end

    def latest_available_property(property)
      @patients.map { |patient| patient.send(property) }.compact.last
    end

    def latest_patient_with_property(property)
      @patients.reverse.find { |patient| patient.send(property).present? }
    end

    def create_cloned_records!(patient, klass, records)
      records.each do |record|
        create_cloned_record!(patient, klass, record)
      end
    end

    def create_cloned_record!(patient, klass, record)
      new_record = klass.create!(
        copyable_attributes(record)
          .merge(id: SecureRandom.uuid, patient_id: patient.id)
      )
      track(klass, record, new_record)
      new_record
    end

    def copyable_attributes(record)
      record.attributes
        .with_indifferent_access
        .except(:id, :patient_id, :created_at, :updated_at)
    end

    def validate_patients(patients)
      if patients.count < 2
        @errors << "Select at least 2 patients to be merged."
      end
    end

    def track(klass, deleted_record, deduped_record)
      DeduplicationLog.create!(
        user_id: @user_id,
        record_type: klass.to_s,
        deleted_record_id: deleted_record.id,
        deduped_record_id: deduped_record.id
      )
    end
  end
end
