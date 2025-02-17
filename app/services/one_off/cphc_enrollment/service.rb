class OneOff::CphcEnrollment::Service
  CPHC_BASE_PATH = ENV["CPHC_BASE_URL"]
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
      patient,
      CPHC_ENROLLMENT_PATH,
      OneOff::CphcEnrollment::EnrollmentPayload.new(patient, cphc_location)
    )
    @individual_id = JSON.parse(response.body.to_s)["individualId"]
    CphcMigrationAuditLog.create(
      cphc_migratable: patient,
      facility_id: facility.id,
      metadata: {
        individual_id: @individual_id,
        patient_id: patient.id,
        cphc_location: cphc_location
      }
    )
  end

  def add_encounter(encounter)
    log = CphcMigrationAuditLog.find_by(cphc_migratable: encounter)

    if log.present?
      logger.error "Encounter already migrated to CPHC", encounter
      @hypertension_examination_id = log.metadata["hypertension_examination_id"]
      @diabetes_examination_id = log.metadata["diabetes_examination_id"]
    end

    add_hypertension_examination(encounter) if encounter.blood_pressures.present? && !@hypertension_examination_id.present?
    add_diabetes_examination(encounter) if encounter.blood_sugars.present? && !@diabetes_examination_id.present?

    if !log.present?
      CphcMigrationAuditLog.create(
        cphc_migratable: encounter,
        facility_id: facility.id,
        metadata: {
          hypertension_examination_id: @hypertension_examination_id,
          diabetes_examination_id: @diabetes_examination_id,
          patient_id: patient.id,
          individual_id: @individual_id,
          cphc_location: cphc_location
        }
      )
    end

    encounter.blood_pressures.each do |blood_pressure|
      add_blood_pressure(blood_pressure)
    end

    # CPHC APIs fail when sending hba1c blood sugar measurements
    encounter.blood_sugars.where.not(blood_sugar_type: :hba1c).each do |blood_sugar|
      add_blood_sugar(blood_sugar)
    end
  end

  def add_hypertension_examination(encounter)
    response = make_post_request(encounter, examination_path(:hypertension), OneOff::CphcEnrollment::HypertensionExaminationPayload.new)
    @hypertension_examination_id = JSON.parse(response.body.to_s)["screeningId"]
  end

  def add_diabetes_examination(encounter)
    response = make_post_request(encounter, examination_path(:diabetes), OneOff::CphcEnrollment::DiabetesExaminationPayload.new)
    @diabetes_examination_id = JSON.parse(response.body.to_s)["screeningId"]
  end

  def add_blood_pressure(blood_pressure)
    log = CphcMigrationAuditLog.find_by(cphc_migratable: blood_pressure)

    if log.present?
      logger.error "Blood pressure already migrated to CPHC", blood_pressure
      return
    end

    response = make_post_request(
      blood_pressure,
      measurement_path(:hypertension, hypertension_examination_id),
      OneOff::CphcEnrollment::BloodPressurePayload.new(blood_pressure)
    )

    measurement_id = JSON.parse(response.body)["encounterId"]
    CphcMigrationAuditLog.create(
      cphc_migratable: blood_pressure,
      facility_id: facility.id,
      metadata: {
        measurement_id: measurement_id,
        patient_id: patient.id,
        individual_id: @individual_id,
        cphc_location: cphc_location
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
        blood_pressure,
        diagnosis_path(:hypertension, hypertension_examination_id),
        OneOff::CphcEnrollment::HypertensionDiagnosisPayload.new(blood_pressure, measurement_id)
      )
    end

    make_post_request(
      blood_pressure,
      treatment_path(:hypertension, hypertension_examination_id),
      OneOff::CphcEnrollment::TreatmentPayload.new(
        blood_pressure,
        prescription_drugs,
        appointment,
        measurement_id
      )
    )

    prescription_drugs.each do |prescription_drug|
      CphcMigrationAuditLog.create(
        cphc_migratable: prescription_drug,
        facility_id: facility.id,
        metadata: {
          patient_id: patient.id,
          individual_id: @individual_id,
          cphc_location: cphc_location
        }
      )
    end

    CphcMigrationAuditLog.create(
      cphc_migratable: appointment,
      facility_id: facility.id,
      metadata: {
        patient_id: patient.id,
        individual_id: @individual_id,
        cphc_location: cphc_location
      }
    )
  end

  def add_blood_sugar(blood_sugar)
    log = CphcMigrationAuditLog.find_by(cphc_migratable: blood_sugar)

    if log.present?
      logger.error "Blood pressure already migrated to CPHC", blood_sugar
      return
    end

    facility = blood_sugar.patient.assigned_facility
    response = make_post_request(
      blood_sugar,
      measurement_path(:diabetes, @diabetes_examination_id),
      OneOff::CphcEnrollment::BloodSugarPayload.new(blood_sugar)
    )

    measurement_id = JSON.parse(response.body.to_s)["encounterId"]

    encounter_date = blood_sugar.device_created_at.to_date
    range = encounter_date.beginning_of_day..encounter_date.end_of_day

    prescription_drugs =
      patient
        .prescription_drugs
        .left_outer_joins(:cphc_migration_audit_log)
        .where(cphc_migration_audit_log: {id: nil})
        .where(device_created_at: range)

    appointment =
      patient
        .appointments
        .left_outer_joins(:cphc_migration_audit_log)
        .where(cphc_migration_audit_log: {id: nil})
        .where(device_created_at: range)
        .order(device_created_at: :desc)
        .first

    CphcMigrationAuditLog.create(
      cphc_migratable: blood_sugar,
      facility_id: facility.id,
      metadata: {
        measurement_id: measurement_id,
        patient_id: patient.id,
        individual_id: @individual_id,
        cphc_location: cphc_location
      }
    )
    unless log.present?
      make_post_request(
        blood_sugar,
        diagnosis_path(:diabetes, @diabetes_examination_id),
        OneOff::CphcEnrollment::DiabetesDiagnosisPayload.new(blood_sugar, measurement_id)
      )
    end

    make_post_request(
      blood_sugar,
      treatment_path(:diabetes, diabetes_examination_id),
      OneOff::CphcEnrollment::DiabetesTreatmentPayload.new(
        blood_sugar,
        prescription_drugs,
        appointment,
        measurement_id
      )
    )
    prescription_drugs.each do |prescription_drug|
      CphcMigrationAuditLog.create(
        cphc_migratable: prescription_drug,
        facility_id: facility.id,
        metadata: {
          patient_id: patient.id,
          individual_id: @individual_id,
          cphc_location: cphc_location
        }
      )
    end

    CphcMigrationAuditLog.create(
      cphc_migratable: appointment,
      facility_id: facility.id,
      metadata: {
        patient_id: patient.id,
        individual_id: @individual_id,
        cphc_location: cphc_location
      }
    )
  end

  def facility
    patient.assigned_facility
  end

  def make_post_request(record, path, payload)
    request = OneOff::CphcEnrollment::Request.new(
      path: path,
      user: user,
      payload: payload
    )

    response = request.post

    if response.code == 200
      logger.info "Request Successful", response.body.to_s
      return response
    end

    CphcMigrationErrorLog.create(
      cphc_migratable: record,
      facility_id: patient.assigned_facility_id,
      patient_id: patient.id,
      failures: {
        timestamp: Time.now,
        path: path,
        headers: request.headers,
        payload: payload.payload,
        response_code: response.code,
        response_body: json_or_str_body(response)
      }
    )

    throw "Request failed", {
      response_code: response.code,
      response_body: json_or_str_body(response)
    }
  end

  def examination_path(diagnosis)
    diagnosis_id = CONFIG[diagnosis][:diagnosis_id]
    "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/program/1/addExamination"
  end

  def measurement_path(diagnosis, screening_id)
    diagnosis_id = CONFIG[diagnosis][:diagnosis_id]
    case diagnosis
    when :hypertension
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/program/1/examination/#{screening_id}"
    when :diabetes
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/examination/#{screening_id}/facility/#{user[:facility_type_id]}"
    end
  end

  def diagnosis_path(diagnosis, screening_id)
    diagnosis_id = CONFIG[diagnosis][:diagnosis_id]
    case diagnosis
    when :hypertension
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/program/1/examination/#{screening_id}/diagnosis"
    when :diabetes
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/examination/#{screening_id}/facility/#{user[:facility_type_id]}/diagnosis"
    end
  end

  def treatment_path(diagnosis, screening_id)
    diagnosis_id = CONFIG[diagnosis][:diagnosis_id]
    case diagnosis
    when :hypertension
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/program/1/examination/#{screening_id}/treatment"
    when :diabetes
      "#{CPHC_BASE_PATH}/condition/#{diagnosis_id}/individual/#{individual_id}/examination/#{screening_id}/facility/#{user[:facility_type_id]}/treatment"
    end
  end

  def logger
    Rails.logger
  end

  def json_or_str_body(response)
    JSON.parse(response.body.to_s)
  rescue
    response.body.to_s
  end

  def cphc_location
    cphc_facility = patient.assigned_facility.cphc_facility

    return chc_dh_location if ["CHC", "DH"].include?(cphc_facility.cphc_facility_type)

    query =
      case cphc_facility.cphc_facility_type
      when "SUBCENTER"
        {cphc_subcenter_id: cphc_facility.cphc_facility_id}
      when "PHC"
        {cphc_phc_id: cphc_facility.cphc_facility_id}
      end

    potential_match = CphcFacilityMapping
      .where(query)
      .search_by_village(patient.address.village_or_colony)
      .first

    other_village = CphcFacilityMapping.find_by(
      query.merge(cphc_village_name: "Other")
    )

    mapping = potential_match || other_village

    {"district_id" => mapping.cphc_district_id,
     "district_name" => mapping.cphc_district_name,
     "taluka_id" => mapping.cphc_taluka_id,
     "taluka_name" => mapping.cphc_taluka_name,
     "phc_id" => mapping.cphc_phc_id,
     "phc_name" => mapping.cphc_phc_name,
     "subcenter_id" => mapping.cphc_subcenter_id,
     "subcenter_name" => mapping.cphc_subcenter_name,
     "village_id" => mapping.cphc_village_id,
     "village_name" => mapping.cphc_village_name}
  end

  def chc_dh_location
    cphc_facility = patient.assigned_facility.cphc_facility

    {"district_id" => cphc_facility.cphc_district_id,
     "district_name" => cphc_facility.cphc_district_name,
     "taluka_id" => cphc_facility.cphc_taluka_id,
     "taluka_name" => cphc_facility.cphc_taluka_name,
     "phc_id" => cphc_facility.cphc_location_details["cphc_phc_id"],
     "phc_name" => cphc_facility.cphc_location_details["cphc_phc_name"],
     "subcenter_id" => cphc_facility.cphc_location_details["cphc_subcenter_id"],
     "subcenter_name" => cphc_facility.cphc_location_details["cphc_subcenter_name"],
     "village_id" => cphc_facility.cphc_location_details["cphc_village_id"],
     "village_name" => cphc_facility.cphc_location_details["cphc_village_name"]}
  end
end
