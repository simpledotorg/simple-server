require 'Pages/base'
class AdminPage < Base
  include Capybara::DSL

  PAGE_HEADING = {xpath: "//h1[text()='Admins']"}
  ALL_INVITE_TABS = {xpath: "//a[@class='btn btn-sm btn-primary']"}
  ADMIN_LIST = {xpath: "//tbody/tr"}
  SUCCESSFUL_MESSAGE = {xpath: "//div[@class='alert alert-primary alert-dismissable fade show']"}
  CROSS_BUTTON = {xpath: "//button[@class='close']/span"}

  def verify_admin_landing_page
    present? PAGE_HEADING
    all_elements(ALL_INVITE_TABS).size.equal?(5)
  end

  def send_invite(name)
    invite_button = all_elements(ALL_INVITE_TABS).select {|element| element.text == name}.first
    invite_button.click
  end

  def admin_list
    all_elements(ADMIN_LIST).size
  end

  def successful_message
    present?(SUCCESSFUL_MESSAGE)
  end

  def click_message_cross_button
    click(CROSS_BUTTON)
    not_present?(SUCCESSFUL_MESSAGE)
  end
end
