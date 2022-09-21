require "selenium-webdriver"

class OneOff::CPHCEnrollment::AuthManager
  attr_reader :auth_token, :is_authorized

  CPHC_API_USER_ID = ENV["CPHC_API_USER_ID"]
  CPHC_API_PASSWORD = ENV["CPHC_API_PASSWORD"]
  CPHC_USER_STATE_CODE = ENV["CPHC_USER_STATE_CODE"]
  CPHC_SIGN_IN_URL = "#{ENV["CPHC_BASE_URL"]}/#/login"

  def initialize
    @auth_token = nil
    @is_authorized = false
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
      logger.error "Could not click on the captcha button"
    end
    logger.info "Waiting to get access token"
    wait.until { driver.find_element(class: "user-profile") }
    @auth_token = get_auth_token
    @is_authorized = true
    driver.quit
  end

  def user
    {user_id: CPHC_API_USER_ID,
     facility_type_id: OneOff::CPHCEnrollment::FACILITY_TYPE_ID["DH"],
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

  def logger
    Rails.logger
  end
end
