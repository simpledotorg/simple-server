require "selenium-webdriver"

class CPHCEnrollment::Service
  CPHC_API_USER_ID = "deo_h_174".freeze
  CPHC_API_PASSWORD = "Password@123".freeze
  CPHC_USER_STATE_CODE = 100
  CPHC_SIGN_IN_URL = "https://ncd-staging.nhp.gov.in/#/login".freeze

  CPHC_ENROLLMENT_PATH = "https://ncd-staging.nhp.gov.in/cphm/enrollment/individual"

  FACILITY_TYPE_ID = {
    "PHC" => 3200,
    "CHC" => 3300,
    "DH" => 3400,
    "TERTIARY" => 3500
  }

  attr_reader :patient
  attr_reader :auth_token
  attr_reader :registry

  def initialize
    @auth_token = nil
    @is_authorized = false
    # @location_finder = CPHCEnrollment::RandomLocationFinder.build
    @registry = CPHCEnrollment::CPHCRegistry.new
  end

  def initial_assessment_path(simple_patient_id)
    individual_id = registry.find_cphc_id(:patient_id, simple_patient_id)
    throw "Unknown patient - individual mapping" unless individual_id
    "https://ncd-staging.nhp.gov.in/cphm/php/individual/#{individual_id}/initialAssessment"
  end

  def medical_history_path(simple_patient_id)
    "#{initial_assessment_path(simple_patient_id)}/patientHistory"
  end

  def vitals_path(simple_patient_id)
    "#{initial_assessment_path(simple_patient_id)}/vitals"
  end

  def prescription_drugs_path(simple_patient_id)
    "#{initial_assessment_path(simple_patient_id)}/currentMedication"
  end

  def call(patient)
    @patient = patient
    enroll_patient(patient)
    update_medical_history(patient.medical_history)
    patient.blood_pressures.each do |blood_pressure|
      update_blood_pressure(blood_pressure)
    end

    patient.blood_sugars.each do |blood_sugar|
      update_blood_sugar(blood_sugar)
    end

    update_prescription_drugs(patient.current_prescription_drugs)

    puts "DONE!!"
  end

  def enroll_patient(patient)
    make_cphc_request(:patient_id, patient.id) do
      enrollment_payload = CPHCEnrollment::EnrollmentPayload.new(patient, location_finder: @location_finder)
      CPHCEnrollment::Request.new(path: CPHC_ENROLLMENT_PATH, user: user, payload: enrollment_payload).post
    end
  end

  def update_medical_history(medical_history)
    make_cphc_request(:medical_history_id, medical_history.id) do
      patient = medical_history.patient
      payload = CPHCEnrollment::MedicalHistoryPayload.new(medical_history)
      CPHCEnrollment::Request.new(path: medical_history_path(patient.id), user: user, payload: payload).post
    end
  end

  def update_blood_pressure(blood_pressure)
    make_cphc_request(:blood_pressure_id, blood_pressure.id) do
      patient = blood_pressure.patient
      payload = CPHCEnrollment::BloodPressurePayload.new(blood_pressure)
      CPHCEnrollment::Request.new(path: vitals_path(patient.id), user: user, payload: payload).post
    end
  end

  def update_blood_sugar(blood_sugar)
    puts "Sending Blood Sugar"
    make_cphc_request(:blood_sugar_id, blood_sugar.id) do
      patient = blood_sugar.patient
      payload = CPHCEnrollment::BloodSugarPayload.new(blood_sugar)
      CPHCEnrollment::Request.new(path: vitals_path(patient.id), user: user, payload: payload).post
    end
  end

  def update_prescription_drugs(prescription_drugs)
    patient_id = prescription_drugs.first.patient_id if prescription_drugs.present?

    return unless patient_id

    make_cphc_request(:prescription_drugs, prescription_drugs.map(&:id)) do
      CPHCEnrollment::Request.new(
        path: prescription_drugs_path(patient_id),
        user: user,
        payload: CPHCEnrollment::PrescriptionDrugsPayload.new(prescription_drugs)
      ).post
    end
  end

  def sign_in(auto_fill: false)
    driver.navigate.to(CPHC_SIGN_IN_URL)
    if auto_fill
      driver.find_element(class: "close", data: { dismiss: "close" }).click
      driver.find_element(id: "username").send_keys(CPHC_API_USER_ID)
      driver.find_element(id: "password").send_keys(CPHC_API_PASSWORD)
    end
    sleep 2
    begin
      driver.find_element(id: "captchaInput").click
    rescue
      print "Could not click on the captcha button"
    end
    puts "Waiting"
    wait.until { driver.find_element(class: "user-profile") }
    @auth_token = get_auth_token
    @is_authorized = true
    driver.quit
  end

  def user
    { user_id: CPHC_API_USER_ID,
      facility_type_id: FACILITY_TYPE_ID["DH"],
      state_code: CPHC_USER_STATE_CODE,
      user_authorization: "Bearer #{auth_token}" }
  end

  def driver
    @driver ||= Selenium::WebDriver.for :firefox
  end

  def get_auth_token
    driver.execute_script(
      "return window.sessionStorage.getItem('access_token')"
    )
  end

  def wait
    @wait ||= Selenium::WebDriver::Wait.new(timeout: 59)
  end

  def make_cphc_request(registry_key, simple_id, &block)
    if @is_authorized
      response = yield

      case response.code
      when 401
        @is_authorized = false
        puts "The request was unauthorized. Pleas check the config and try again."
      when 200
        puts "Request completed successfully"
        response_body = JSON.parse(response.body)
        if registry_key == :patient_id
          registry.add(registry_key, simple_id, response_body["individualId"])
        else
          registry.add(registry_key, simple_id)
        end
      else
        puts "Request Failed: #{registry_key}, #{simple_id}: #{response}"
      end

      puts "Success  #{response}"
      response
    else
      sign_in(auto_fill: true)
      make_cphc_request(registry_key, simple_id, &block)
    end
  end
end
