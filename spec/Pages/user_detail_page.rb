class UserDetailsPage < ApplicationPage

  include Capybara::DSL

  PAGE_HEADING = {xpath: "//h1[text()='User details']"}
  NAME_LABEL = {xpath: "//strong[text()='Name:']"}
  PHONE_NUMBER_LABEL = {xpath: "//strong[text()='Phone number:']"}
  REGISTRATION_FACILITY_LABEL = {xpath: "//strong[text()='Registration Facility:']"}
  SYNC_STATUS_LABEL = {xpath: "//strong[text()='Sync status:']"}
  SYNC_REASON_LABEL = {xpath: "//strong[text()='Sync reason:']"}
  FIRST_LOGGED_IN_LABEL = {xpath: "//strong[text()='First logged in at:']"}
  EDIT_LINK = {xpath: "//a[text()='Edit']"}
  DENY_ACCESS_LINK = {xpath: "//a[text()='Deny access']"}

  def verify_user_detail_page
    present?(PAGE_HEADING)
    present?(NAME_LABEL)
    present?(PHONE_NUMBER_LABEL)
    present?(REGISTRATION_FACILITY_LABEL)
    present?(SYNC_REASON_LABEL)
    present?(SYNC_STATUS_LABEL)
    present?(FIRST_LOGGED_IN_LABEL)
    present?(EDIT_LINK)
    present?(DENY_ACCESS_LINK)
  end

  def click_on_edit_link
    click(EDIT_LINK)
  end
end
