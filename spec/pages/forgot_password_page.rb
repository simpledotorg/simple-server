class ForgotPassword < ApplicationPage

  EMAIL_TEXT_BOX = { id: 'admin_email' }
  RESET_PASSWORD_BUTTON = { xpath: "//input[@class='btn btn-primary']" }
  MESSAGE = { xpath: "//div[@class='alert alert-primary alert-dismissable fade show']" }
  LOGIN = { xpath: "//div/a[@href='/admins/sign_in']" }
  MESSAGE_CROSS_BUTTON = { xpath: "//button[@class='close']/span" }
  UNLOCK_INSTRUCTION_BUTTON = { xpath: "//a[@href='/admins/unlock/new']" }
  RESEND_INSTRUCTION_BUTTON = { xpath: "//input[@class='btn btn-primary']" }

  def do_reset_password(email)
    type(EMAIL_TEXT_BOX, email)
    click(RESET_PASSWORD_BUTTON)
    present?(MESSAGE)
    click(MESSAGE_CROSS_BUTTON)
    not_present?(MESSAGE)
  end

  def resend_unlock_instruction(email)
    click(UNLOCK_INSTRUCTION_BUTTON)
    type(EMAIL_TEXT_BOX, email)
    click(RESEND_INSTRUCTION_BUTTON)
    #assertion pending because of defect
  end

  def click_login_link
    click(LOGIN)
  end
end