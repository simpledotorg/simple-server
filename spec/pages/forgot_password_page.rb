class ForgotPassword < ApplicationPage

  EMAIL_TEXT_BOX = { id: 'admin_email' }.freeze
  RESET_PASSWORD_BUTTON = { css: "div.text-right>input" }.freeze
  MESSAGE = { css: 'div.show' }.freeze
  MESSAGE_CROSS_BUTTON = { css: "div.show>button" }.freeze
  LOGIN = { css: "a[href='/admins/sign_in']" }.freeze
  UNLOCK_INSTRUCTION_BUTTON = { css: "a[href='/admins/unlock/new']"}.freeze
  RESEND_INSTRUCTION_BUTTON = { css: "div.text-right>input" }.freeze

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