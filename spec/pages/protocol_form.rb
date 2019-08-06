class ProtocolFormPage < ApplicationPage

  #this screen is used for creation and updation of protocol
  PROTOCOL_NAME = { id: "protocol_name" }.freeze
  PROTOCOL_FOLLOWUP_DAYS = { id: "protocol_follow_up_days" }.freeze
  CREATE_PROTOCOL_BUTTON = { css: "input.btn-primary" }.freeze

  def create_new_protocol(name, followup_days)
    type(PROTOCOL_NAME, name)
    type(PROTOCOL_FOLLOWUP_DAYS, followup_days)
    click(CREATE_PROTOCOL_BUTTON)
  end

  def update_protocol_followup_days(followup_days)
    type(PROTOCOL_FOLLOWUP_DAYS, followup_days)
    click(CREATE_PROTOCOL_BUTTON)
  end

  def update_protocol_name(name)
    type(PROTOCOL_NAME, name)
    click(CREATE_PROTOCOL_BUTTON)
  end
end