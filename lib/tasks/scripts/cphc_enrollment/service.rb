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
    @location_finder = CPHCEnrollment::RandomLocationFinder.build
    @registry = CPHCEnrollment::CPHCRegistry.new
  end

  def medical_history_path(simple_patient_id)
    individual_id = registry.find_cphc_id(:patient_id, simple_patient_id)
    throw "Unknown patient - individual mapping" unless individual_id
    "https://ncd-staging.nhp.gov.in/cphm/php/individual/#{individual_id}/initialAssessment/patientHistory"
  end

  def call(patient)
    @patient = patient
    enroll_patient(patient)
    update_medical_history(patient.medical_history)
  end

  def enroll_patient(patient)
    response = make_cphc_request do
      enrollment_payload = CPHCEnrollment::EnrollmentPayload.new(patient, location_finder: @location_finder)
      CPHCEnrollment::Request.new(path: CPHC_ENROLLMENT_PATH, user: user, payload: enrollment_payload).post
    end

    response_body = JSON.parse(response.body)

    registry.add(:patient_id, patient.id, response_body["individualId"])
  end

  def update_medical_history(medical_history)
    make_cphc_request do
      patient = medical_history.patient
      payload = CPHCEnrollment::MedicalHistoryPayload.new(medical_history)
      CPHCEnrollment::Request.new(path: medical_history_path(patient.id), user: user, payload: payload).post
    end
  end

  def sign_in(auto_fill: false)
    driver.navigate.to(CPHC_SIGN_IN_URL)
    if auto_fill
      driver.find_element(class: "close", data: {dismiss: "close"}).click
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
    {user_id: CPHC_API_USER_ID,
     facility_type_id: FACILITY_TYPE_ID["DH"],
     state_code: CPHC_USER_STATE_CODE,
     user_authorization: "Bearer #{auth_token}"}
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

  def make_cphc_request(&block)
    if @is_authorized
      response = yield

      case response.code
      when 401
        @is_authorized = false
        puts "The request was unauthorized. Pleas check the config and try again."
      when 200
        puts "Result Successful successfully"
      else
        puts "Request Failed: #{patient.full_name}"
      end

      puts JSON.parse(response.body)
      response
    else
      sign_in(auto_fill: true)
      yield
    end
  end
end
