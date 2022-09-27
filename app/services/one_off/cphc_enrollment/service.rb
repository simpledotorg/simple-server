class OneOff::CPHCEnrollment::Service
  CPHC_BASE_PATH = "#{ENV["CPHC_BASE_URL"]}/cphm"
  CPHC_ENROLLMENT_PATH = "#{CPHC_BASE_PATH}/enrollment/individual"

  CONFIG = {
    hypertension: {
      diagnosis_id: "500"
    },
    diabetes: {
      diagnosis_id: "600"
    }
  }

  attr_reader :patient
  attr_reader :user
  attr_reader :individual_id
  attr_reader :hypertension_examination_id
  attr_reader :diabetes_examination_id

  def initialize(patient, user)
    @patient = patient
    @user = user
    @individual_id = nil
    @hypertension_examination_id = nil
    @diabetes_examination_id = nil
  end

  def call
    logger.info "Enrolling Patient", {id: patient.id, full_name: patient.full_name}
    enroll_patient
    patient.encounters.each do |encounter|
      add_encounter(encounter)
    end
    logger.info "Finished Syncing patient", {id: patient.id, full_name: patient.full_name}
  end

  def enroll_patient
    log = CphcMigrationAuditLog.find_by(cphc_migratable: patient)
    if log.present?
      logger.error "Patient already migrated to CPHC", patient
      @individual_id = log.metadata["individual_id"]
      return
    end

    response = make_post_request(
      CPHC_ENROLLMENT_PATH,
      OneOff::CPHCEnrollment::EnrollmentPayload.new(patient)
    )
    @individual_id = JSON.parse(response.body)["individualId"]
    CphcMigrationAuditLog.create(cphc_migratable: patient, metadata: {
      individual_id: @individual_id
    })
  end

  def add_encounter(encounter)
    log = CphcMigrationAuditLog.find_by(cphc_migratable: encounter)

    if log.present?
      logger.error "Encounter already migrated to CPHC", encounter
      @hypertension_examination_id = log.metadata["hypertension_examination_id"]
      @diabetes_examination_id = log.metadata["diabetes_examination_id"]
    end

    add_hypertension_examination if encounter.blood_pressures.present? && !@hypertension_examination_id.present?
    add_diabetes_examination if encounter.blood_sugars.present? && !@diabetes_examination_id.present?

    if !log.present?
      CphcMigrationAuditLog.create(cphc_migratable: encounter, metadata: {
        hypertension_examination_id: @hypertension_examination_id,
        diabetes_examination_id: @diabetes_examination_id
      })
    end

    encounter.blood_pressures.each do |blood_pressure|
      add_blood_pressure(blood_pressure)
    end

    # CPHC APIs fail when sending hba1c blood sugar measurements
    encounter.blood_sugars.where.not(blood_sugar_type: :hba1c).each do |blood_sugar|
      add_blood_sugar(blood_sugar)
    end
  end

  def add_hypertension_examination
    response = make_post_request(examination_path(:hypertension), nil)
    @hypertension_examination_id = JSON.parse(response.body)["screeningId"]
  end

  def add_diabetes_examination
    response = make_post_request(examination_path(:diabetes), nil)
    @diabetes_examination_id = JSON.parse(response.body)["screeningId"]
  end

  def add_blood_pressure(blood_pressure)
    log = CphcMigrationAuditLog.find_by(cphc_migratable: blood_pressure)

    if log.present?
      logger.error "Blood pressure already migrated to CPHC", blood_pressure
      return
    end

    response = make_post_request(
      measurement_path(:hypertension, hypertension_examination_id),
      OneOff::CPHCEnrollment::BloodPressurePayload.new(blood_pressure)
    )
    measurement_id = JSON.parse(response.body)["encounterId"]
    CphcMigrationAuditLog.create(
      cphc_migratable: blood_pressure,
      metadata: {
        measurement_id: measurement_id
      }
    )

    encounter_date = blood_pressure.device_created_at.to_date

    range = encounter_date.beginning_of_day..encounter_date.end_of_day

    prescription_drugs =
      patient
        .prescription_drugs
        .where(device_created_at: range)

    appointment =
      patient
        .appointments
        .where(device_created_at: range)
        .order(device_created_at: :desc)
        .first

    unless log.present?
      make_post_request(
        diagnosis_path(:hypertension, hypertension_examination_id),
        OneOff::CPHCEnrollment::HypertensionDiagnosisPayload.new(blood_pressure, measurement_id)
      )
    end

    make_post_request(
      treatment_path(:hypertension, hypertension_examination_id),
      OneOff::CPHCEnrollment::TreatmentPayload.new(
        blood_pressure,
        prescription_drugs,
        appointment,
        measurement_id
      )
    )

    prescription_drugs.each do |prescription_drug|
      CphcMigrationAuditLog.create(cphc_migratable: prescription_drug)
    end
    CphcMigrationAuditLog.create(cphc_migratable: appointment)
  end

  def add_blood_sugar(blood_sugar)
    log = CphcMigrationAuditLog.find_by(cphc_migratable: blood_sugar)
    if log.present?
      logger.error "Blood pressure already migrated to CPHC", blood_sugar
      return
    end

    facility_type_id = OneOff::CPHCEnrollment::FACILITY_TYPE_ID["DH"]
    response = make_post_request(
      measurement_path(:diabetes, @diabetes_examination_id, facility_type_id),
      OneOff::CPHCEnrollment::BloodSugarPayload.new(blood_sugar)
    )

    measurement_id = JSON.parse(response.body)["encounterId"]

    CphcMigrationAuditLog.create(
      cphc_migratable: blood_sugar,
      metadata: {
        measurement_id: measurement_id
      }
    )
    make_post_request(
      diagnosis_path(:diabetes, @diabetes_examination_id, facility_type_id),
      OneOff::CPHCEnrollment::DiabetesDiagnosisPayload.new(blood_sugar, measurement_id)
    )
  end

  def make_post_request(path, payload)
    response = OneOff::CPHCEnrollment::Request.new(
      path: path,
      user: user,
      payload: payload
    ).post

    case response.code
    when 401
      throw "The request was unauthorized. Pleas check the config and try again."
    when 404
      logger.error "Path not found", path
      throw "Not found", path
    when 200
      logger.info "Request Successful", response.body
    else
      logger.error "Request Failed", {response_body: JSON.parse(response.body), status: response.status, payload: payload.payload}
      throw "Request Failed: #{response.body}"
    end

    response
  end

  def examination_path(diagnosis)
    diagnosis_id = CONFIG[diagnosis][:diagnosis_id]
    "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/program/1/addExamination"
  end

  def measurement_path(diagnosis, screening_id, facility_type_id = nil)
    diagnosis_id = CONFIG[diagnosis][:diagnosis_id]
    case diagnosis
    when :hypertension
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/program/1/examination/#{screening_id}"
    when :diabetes
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/examination/#{screening_id}/facility/#{facility_type_id}"
    end
  end

  def diagnosis_path(diagnosis, screening_id, facility_type_id = nil)
    diagnosis_id = CONFIG[diagnosis][:diagnosis_id]
    case diagnosis
    when :hypertension
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/program/1/examination/#{screening_id}/diagnosis"
    when :diabetes
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/examination/#{screening_id}/facility/#{facility_type_id}/diagnosis"
    end
  end

  def treatment_path(diagnosis, screening_id, facility_type_id = nil)
    diagnosis_id = CONFIG[diagnosis][:diagnosis_id]
    "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/program/1/examination/#{screening_id}/treatment"
  end

  def logger
    Rails.logger
  end
end
