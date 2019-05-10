require 'Pages/base'
class UsersPage < Base
  include Capybara::DSL

  PAGE_HEADING = {xpath: "//h1"}
  DISTRICT_LIST = {xpath: "//h2"}
  Users_LIST = {xpath: "//tbody/tr"}

  def verify_users_landing_page
    present?(PAGE_HEADING)
    verifyText(PAGE_HEADING, "Users")
  end

  def all_district
    all_elements(DISTRICT_LIST)
  end

  def all_user
    all_elements(Users_LIST)
  end

  def click_edit_link(user_name)
    find(:xpath, "//td/a[text()='#{user_name}']/../../td/a[text()='Edit']").click
  end

  def click_registered_facility_link(user_name)
    find(:xpath, "//td/a[text()='#{user_name}']/../../td[5]/a").click
  end
end
