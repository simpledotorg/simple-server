class InvitationPage < ApplicationPage

  PAGE_HEADING = {xpath: "//h1"}
  EMAIL = {id: "admin_email"}
  SEND_INVITATION_BUTTON = {xpath: "//input[@class='btn btn-primary']"}
  SELECT_TEXT = {xpath: "//h3[text()='Select Organizations']"}
  ORGANIZATION_LABEL = {xpath: "//label[text()='Organizations']"}
  INVALID_FEEDBACK = {xpath: "//div[@class='invalid-feedback']"}

  def send_invitation_to_owner(email)
    present?(PAGE_HEADING)
    type(EMAIL, email)
    click(SEND_INVITATION_BUTTON)
  end

  def select_organization(name)
    find(:xpath, "//label[text()='#{name}']/../input").click
  end

  def select_facility_group(name)
    find(:xpath, "//label[text()='#{name}']/../input").click
  end

  def send_invitation_organization_owner(email, org_name)
    present?(PAGE_HEADING)
    type(EMAIL, email)
    select_organization(org_name)
    click(SEND_INVITATION_BUTTON)
  end

  def send_invitation_others(email, facility_name)
    present?(PAGE_HEADING)
    type(EMAIL, email)
    select_facility_group(facility_name)
    click(SEND_INVITATION_BUTTON)
  end

  def invalid_feedback
    present?(INVALID_FEEDBACK)
  end

  def select_invite_multiple_organization(email, org_name)
    present?(PAGE_HEADING)
    type(EMAIL, email)
    org_name.each do |org|
      find(:xpath, "//label[text()='#{org}']/../input").click
    end
    click(SEND_INVITATION_BUTTON)
  end

  def send_multiple_invitation_others(email, facility)
    present?(PAGE_HEADING)
    type(EMAIL, email)
    facility.each do |name|
      find(:xpath, "//label[text()='#{name}']/../input").click
    end
    click(SEND_INVITATION_BUTTON)
  end
end
