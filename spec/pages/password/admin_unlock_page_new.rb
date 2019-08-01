class AdminUnlockPageNew < ApplicationPage

  EMAIL_TEXT_BOX = { id: 'admin_email' }.freeze
  RESET_PASSWORD_BUTTON = { css: "div.text-right>input" }.freeze
  MESSAGE = { css: 'div.alert-primary' }.freeze
  MESSAGE_CROSS_BUTTON = { css: "button.close" }.freeze
  RESEND_INSTRUCTION_BUTTON = { css: "div.text-right>input" }.freeze

  def resend_unlock_instruction(email)
    type(EMAIL_TEXT_BOX, email)
    click(RESEND_INSTRUCTION_BUTTON)
    #assertion pending because of defect
  end
end

