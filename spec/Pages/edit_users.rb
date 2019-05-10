require 'Pages/base'
class EditUserPage < Base

  include Capybara::DSL

  PAGE_HEADING = {xpath: "//h1"}
  FULL_NAME_LABEL = {xpath: "//label[@for='user_name']"}
  FULL_NAME_TEXT_FIELD = {id: "user_name"}

  PHONE_NUMBER_LABEL = {xpath: "//label[@for='user_phone_number']"}
  PHONE_NUMBER_TEXT_FIELD = {id: "user_phone_number"}

  PIN_LABEL = {xpath: "//label[@for='user_password']"}
  PIN = {id: "user_password"}

  PIN_CONFIRMATION_LABEL = {xpath: "//label[@for='user_password_confirmation']"}
  CONFIRMATION_PIN = {id: "user_password_confirmation"}

  STATUS_LABEL = {xpath: "//label[@for='user_sync_approval_status']"}
  STATUS_RADIO_BUTTON_LIST = {xpath: "//input[@type='radio']"}

  REGISTRATION_FACILITY_LABEL = {xpath: "//label[@for='user_registration_facility_id']"}
  # FACILITY_DROPDOWN={xpath: "//select[@class='form-control']"}

  UPDATE_USER_BUTTON = {xpath: "//input[@class='btn btn-primary']"}


  def verify_Edit_user_landing_page
    present?(PAGE_HEADING)
    # verifyText(:PAGE_HEADING,"Edit user")
    present?(FULL_NAME_LABEL)
    present?(FULL_NAME_TEXT_FIELD)
    present?(PHONE_NUMBER_LABEL)
    present?(PHONE_NUMBER_TEXT_FIELD)
    present?(PIN_LABEL)
    present?(PIN)
    present?(PIN_CONFIRMATION_LABEL)
    present?(CONFIRMATION_PIN)
    present?(STATUS_LABEL)
    present?(STATUS_RADIO_BUTTON_LIST)
    present?(REGISTRATION_FACILITY_LABEL)
    present?(FACILITY_DROPDOWN)
    present?(UPDATE_USER_BUTTON)
  end

  #confirm_pin,status,facility

  def set_full_name(name)
    type(FULL_NAME_TEXT_FIELD, name)
  end

  def set_phone_number(phone)
    type(PHONE_NUMBER_TEXT_FIELD, phone)
  end

  def set_pin(pin)
    #need to check pin shold be nil
    type(PIN, pin)
  end

  def set_confirm_pin(pin)
    #need to check pin shold be nil
    type(CONFIRMATION_PIN, pin)
  end

  def click_Update_user_button
    click(UPDATE_USER_BUTTON)
  end

  def edit_status(status)
    find(:xpath, "//label[text()='#{status}']/../input").click
    click_Update_user_button
  end

  def edit_registration_facility(name)
    puts name
    find(:xpath, "//select[@class='form-control']").find(:option, name).select_option
  end
end