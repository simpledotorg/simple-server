class LoginPage < ApplicationPage
  EMAIL_TEXT_BOX = { id: 'admin_email' }
  PASSWORD_TEXT_BOX = { id: 'admin_password' }.freeze
  LOGIN_BUTTON = { xpath: "//input[@class='btn btn-primary']" }.freeze
  REMEMBER_ME_CHECKBOX = { id: 'admin_remember_me' }.freeze
  FORGOT_PASSWORD_LINK = { xpath: "//a[text()='Forgot your password?']" }.freeze
  UNLOCK_INSTRUCTION_LINK = { xpath: "//a[contains(text(),'receive unlock instructions')]" }.freeze
  LOGIN_LINK = { xpath: "//a[@class='nav-link']" }.freeze
  ERROR_MESSAGE = { xpath: "//div[contains(@class,'alert-warning')]" }.freeze
  MESSAGE_CROSS_BUTTON = { xpath: "//button[@type='button']/span" }.freeze
  SUCCESSFUL_LOGOUT_MESSAGE = { xpath: "//div[@class='alert alert-primary alert-dismissable fade show']" }.freeze

  def do_login(emailID, password)
    type(EMAIL_TEXT_BOX, emailID)
    type(PASSWORD_TEXT_BOX, password)
    click(LOGIN_BUTTON)
  end

  def click_forgot_password_link
    click(FORGOT_PASSWORD_LINK)
  end

  def click_errormessage_cross_button
    click(MESSAGE_CROSS_BUTTON)
    not_present?(ERROR_MESSAGE)
  end

  def is_errormessage_present
    present?(ERROR_MESSAGE)
  end

  def is_successful_logout_message_present
    present?(SUCCESSFUL_LOGOUT_MESSAGE)
    present?(LOGIN_BUTTON)
  end

  def click_successful_message_cross_button
    click(MESSAGE_CROSS_BUTTON)
    not_present?(SUCCESSFUL_LOGOUT_MESSAGE)
  end

  def set_email_text_box(email)
    type(EMAIL_TEXT_BOX,email)
  end

  def set_password_text_box(pwd)
    type(PASSWORD_TEXT_BOX, pwd)
  end
end
